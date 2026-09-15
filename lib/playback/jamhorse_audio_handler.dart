import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show Value;
import 'package:jamhorse/core/logging.dart';
import 'package:jamhorse/data/database.dart' as db;
import 'package:jamhorse/domain/contracts.dart';
import 'package:jamhorse/domain/models.dart' as domain;
import 'package:jamhorse/playback/queue_shuffle_order.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Local file paths of one profile's finished downloads, keyed by item id.
typedef LocalSourceResolver =
    Future<Map<String, String>> Function(String profileId);
typedef ArtworkResolver =
    Future<Uri?> Function(domain.AuthSession session, domain.LibraryItem item);

/// Playable tracks for an album, artist, playlist, or genre.
typedef TrackResolver =
    Future<List<domain.LibraryItem>> Function(
      domain.AuthSession session,
      domain.LibraryItem item,
    );

class JamHorseAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler
    implements PlaybackCoordinator {
  JamHorseAudioHandler(
    this._gateway, {
    required this._reporter,
    this._tracksFor,
    AudioPlayer? player,
    this._localSourceResolver,
    this._artworkResolver,
    this._database,
  }) : _player = player ?? AudioPlayer() {
    _bindPlayer();
  }

  /// Coalesces bursts of queue and state changes into one write.
  static const _persistDelay = Duration(seconds: 2);

  /// While playing: how often position is saved and reported to Jellyfin.
  static const _heartbeat = Duration(seconds: 10);

  final JellyfinGateway _gateway;
  final PlaybackReporter _reporter;
  final TrackResolver? _tracksFor;
  final AudioPlayer _player;
  final LocalSourceResolver? _localSourceResolver;
  final ArtworkResolver? _artworkResolver;
  final db.AppDatabase? _database;
  final _snapshots = StreamController<domain.PlaybackSnapshot>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  final _localArtwork = <String, Uri>{};

  domain.AuthSession? _session;
  List<domain.LibraryItem> _items = const [];
  List<int> _playOrder = const [];
  List<domain.LibraryItem> _browseLibrary = const [];
  domain.PlaybackSnapshot _snapshot = const domain.PlaybackSnapshot();
  QueueShuffleOrder _shuffleOrder = QueueShuffleOrder();
  Timer? _sleepTimer;
  Timer? _persistTimer;
  bool _reportInFlight = false;
  bool _loading = false;
  bool _queueDirty = false;
  int _loadGeneration = 0;
  int? _lastIndex;

  /// Tracks inserted with "Play next" / "Add to queue" that have not played
  /// yet; new "Add to queue" items go after them.
  int _queuedAhead = 0;

  /// A queue restored at launch has not started playing, so Jellyfin hears
  /// about it only once the user presses play.
  bool _startReportPending = false;
  domain.LibraryItem? _reportedItem;
  Duration _reportedPosition = Duration.zero;
  String? _playSessionId;
  Future<void> _transitionSerial = Future.value();

  Future<void> initialize() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    Timer.periodic(_heartbeat, (_) {
      if (!_player.playing) return;
      _schedulePersist();
      unawaited(_reportProgress());
    });
  }

  @override
  domain.PlaybackSnapshot get currentSnapshot => _snapshot;

  @override
  int? get audioSessionId => _player.androidAudioSessionId;

  @override
  Stream<domain.PlaybackSnapshot> get snapshots => _snapshots.stream;

  @override
  Future<void> load(
    domain.AuthSession session,
    List<domain.LibraryItem> queueItems, {
    int initialIndex = 0,
    bool autoPlay = true,
    bool? shuffle,
  }) {
    return _loadQueue(
      session,
      queueItems,
      initialIndex: initialIndex,
      autoPlay: autoPlay,
      shuffle: shuffle,
    );
  }

  Future<void> _loadQueue(
    domain.AuthSession session,
    List<domain.LibraryItem> queueItems, {
    required int initialIndex,
    required bool autoPlay,
    bool? shuffle,
    Duration initialPosition = Duration.zero,
  }) async {
    if (queueItems.isEmpty) return;
    final generation = ++_loadGeneration;
    await _reportStopped();
    if (generation != _loadGeneration) return;
    _loading = true;
    _session = session;
    _items = List.unmodifiable(queueItems);
    _queuedAhead = 0;
    _startReportPending = false;

    try {
      queue.add(_items.map(_toMediaItem).toList(growable: false));
      final sources = await _createSources(session, queueItems);
      if (generation != _loadGeneration) return;
      final safeIndex = initialIndex.clamp(0, queueItems.length - 1);
      _shuffleOrder = QueueShuffleOrder();
      await _player.setAudioSources(
        sources,
        initialIndex: safeIndex,
        initialPosition: initialPosition,
        preload: autoPlay,
        shuffleOrder: _shuffleOrder,
      );
      if (generation != _loadGeneration) return;
      final shuffled = shuffle ?? _player.shuffleModeEnabled;
      if (shuffled) await _player.shuffle();
      if (shuffled != _player.shuffleModeEnabled) {
        await _player.setShuffleModeEnabled(shuffled);
      }
      if (generation != _loadGeneration) return;
      _refreshPlayOrder();
      _lastIndex = safeIndex;
      _beginItem(session, _items[safeIndex], generation);
      _queueDirty = true;
      _schedulePersist();
      _updateSnapshot(forcePlatformUpdate: true);
    } finally {
      if (generation == _loadGeneration) _loading = false;
    }
    if (generation != _loadGeneration) return;
    if (autoPlay) {
      await _reportStarted();
      // just_audio's play() completes only when playback pauses, so it is not
      // awaited: holding the load open would suppress track-change handling.
      unawaited(_startPlayback());
    } else {
      _startReportPending = true;
    }
  }

  @override
  Future<void> play() async {
    if (_startReportPending) {
      _startReportPending = false;
      unawaited(_reportStarted());
    }
    await _player.play();
  }

  Future<void> _startPlayback() async {
    try {
      await _player.play();
    } catch (error) {
      appLog.warning('Playback could not start: $error');
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    await persistNow();
    await _reportProgress();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _schedulePersist();
    await _reportProgress();
  }

  @override
  Future<void> skipNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  @override
  Future<void> skipToNext() => skipNext();

  @override
  Future<void> skipPrevious() async {
    if (_player.position > const Duration(seconds: 4)) {
      return seek(Duration.zero);
    }
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await seek(Duration.zero);
    }
  }

  @override
  Future<void> skipToPrevious() => skipPrevious();

  @override
  Future<void> skipToIndex(int index) async {
    if (index < 0 || index >= _items.length) return;
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> skipToQueueItem(int index) => skipToIndex(index);

  @override
  Future<void> moveQueueItem(int from, int to) async {
    if (from < 0 ||
        from >= _items.length ||
        to < 0 ||
        to >= _items.length ||
        from == to) {
      return;
    }
    final mutable = _items.toList();
    final item = mutable.removeAt(from);
    mutable.insert(to, item);
    _items = List.unmodifiable(mutable);
    await _player.moveAudioSource(from, to);
    _queueChanged();
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    if (index < 0 || index >= _items.length || _items.length == 1) return;
    final mutable = _items.toList()..removeAt(index);
    _items = List.unmodifiable(mutable);
    await _player.removeAudioSourceAt(index);
    _queueChanged();
  }

  @override
  Future<void> playNext(List<domain.LibraryItem> items) {
    return _insertUpNext(items, afterQueued: false);
  }

  @override
  Future<void> addToQueue(List<domain.LibraryItem> items) {
    return _insertUpNext(items, afterQueued: true);
  }

  Future<void> _insertUpNext(
    List<domain.LibraryItem> items, {
    required bool afterQueued,
  }) async {
    final session = _session;
    if (session == null) return;
    final accepted = items
        .where((item) => item.profileId == session.profile.profileId)
        .toList(growable: false);
    if (accepted.isEmpty) return;
    if (_items.isEmpty || _player.currentIndex == null) {
      return _loadQueue(session, accepted, initialIndex: 0, autoPlay: true);
    }
    final generation = _loadGeneration;
    final sources = await _createSources(session, accepted);
    final current = _player.currentIndex;
    if (generation != _loadGeneration || current == null) return;

    final ahead = afterQueued ? _queuedAhead : 0;
    final int insertAt;
    if (_player.shuffleModeEnabled) {
      // Sources go at the end; the shuffle order places them right after the
      // current track (and earlier queued picks) in play order.
      final position = _player.shuffleIndices.indexOf(current);
      _shuffleOrder.anchorNextInsert(position + 1 + ahead);
      insertAt = _items.length;
    } else {
      insertAt = min(current + 1 + ahead, _items.length);
    }
    await _player.insertAudioSources(insertAt, sources);
    _items = List.unmodifiable([
      ..._items.take(insertAt),
      ...accepted,
      ..._items.skip(insertAt),
    ]);
    _queuedAhead += accepted.length;
    _queueChanged();
  }

  void _queueChanged() {
    _refreshPlayOrder();
    queue.add(_items.map(_toMediaItem).toList(growable: false));
    _queueDirty = true;
    _updateSnapshot();
    _schedulePersist();
  }

  @override
  Future<void> setShuffle(bool enabled) async {
    if (enabled) await _player.shuffle();
    await _player.setShuffleModeEnabled(enabled);
    _queuedAhead = 0;
    _refreshPlayOrder();
    _updateSnapshot();
    _schedulePersist();
  }

  @override
  Future<void> setRepeat(domain.RepeatMode mode) async {
    await _player.setLoopMode(switch (mode) {
      domain.RepeatMode.off => LoopMode.off,
      domain.RepeatMode.all => LoopMode.all,
      domain.RepeatMode.one => LoopMode.one,
    });
    _updateSnapshot();
    _schedulePersist();
  }

  @override
  Future<void> setVolume(double volume) {
    return _player.setVolume(volume.clamp(0, 1));
  }

  @override
  Future<void> setSleepTimer(Duration? duration) async {
    _sleepTimer?.cancel();
    _snapshot = duration == null
        ? _snapshot.copyWith(clearSleepDeadline: true)
        : _snapshot.copyWith(sleepDeadline: DateTime.now().add(duration));
    if (duration != null) {
      _sleepTimer = Timer(duration, () async {
        await pause();
        await setSleepTimer(null);
      });
    }
    if (!_snapshots.isClosed) _snapshots.add(_snapshot);
    _schedulePersist();
  }

  @override
  Future<void> updateItemMetadata(domain.LibraryItem item) async {
    final index = _items.indexWhere(
      (entry) => entry.profileId == item.profileId && entry.id == item.id,
    );
    if (index < 0) return;
    final mutable = _items.toList();
    mutable[index] = item;
    _items = List.unmodifiable(mutable);
    if (_reportedItem?.id == item.id &&
        _reportedItem?.profileId == item.profileId) {
      _reportedItem = item;
    }
    final mediaItems = _items.map(_toMediaItem).toList(growable: false);
    queue.add(mediaItems);
    if (_player.currentIndex == index) mediaItem.add(mediaItems[index]);
    _updateSnapshot();
  }

  @override
  Future<void> stop() async {
    _loadGeneration++;
    _loading = false;
    await _reportStopped();
    await persistNow();
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> reset() async {
    await stop();
    _sleepTimer?.cancel();
    _session = null;
    _items = const [];
    _playOrder = const [];
    _browseLibrary = const [];
    _queuedAhead = 0;
    _lastIndex = null;
    _startReportPending = false;
    _queueDirty = false;
    _snapshot = const domain.PlaybackSnapshot();
    queue.add(const []);
    mediaItem.add(null);
    if (!_snapshots.isClosed) _snapshots.add(_snapshot);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) {
    return setRepeat(switch (repeatMode) {
      AudioServiceRepeatMode.one => domain.RepeatMode.one,
      AudioServiceRepeatMode.all ||
      AudioServiceRepeatMode.group => domain.RepeatMode.all,
      _ => domain.RepeatMode.off,
    });
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) {
    return setShuffle(shuffleMode != AudioServiceShuffleMode.none);
  }

  void _bindPlayer() {
    _subscriptions
      ..add(
        _player.playerStateStream.listen((state) {
          _updateSnapshot();
          if (state.processingState == ProcessingState.completed &&
              _player.loopMode == LoopMode.off) {
            unawaited(_reportStopped());
            unawaited(persistNow());
          }
        }),
      )
      ..add(
        _player.positionStream.listen((position) {
          _reportedPosition = position;
          _updateSnapshot();
        }),
      )
      ..add(_player.bufferedPositionStream.listen((_) => _updateSnapshot()))
      ..add(_player.currentIndexStream.listen(_onIndexChanged))
      ..add(_player.volumeStream.listen((_) => _updateSnapshot()))
      ..add(_player.shuffleModeEnabledStream.listen((_) => _updateSnapshot()))
      ..add(_player.loopModeStream.listen((_) => _updateSnapshot()))
      ..add(
        _player.positionDiscontinuityStream.listen(
          (_) => _updateSnapshot(forcePlatformUpdate: true),
        ),
      );
  }

  Future<void> _onIndexChanged(int? index) async {
    if (_loading || index == null || index < 0 || index >= _items.length) {
      return;
    }
    _consumeQueuedAhead(index);
    _transitionSerial = _transitionSerial.then((_) async {
      final session = _session;
      if (session == null || index >= _items.length) return;
      final item = _items[index];
      if (_reportedItem?.id == item.id &&
          _reportedItem?.profileId == item.profileId) {
        _updateSnapshot();
        return;
      }
      await _reportStopped();
      _updateSnapshot();
      _beginItem(session, item, _loadGeneration);
      if (_player.playing) {
        await _reportStarted();
      } else {
        _startReportPending = true;
      }
      _schedulePersist();
    });
    await _transitionSerial;
  }

  /// Moving forward through queued picks uses them up; jumping backwards
  /// abandons the rest of the manual queue, as in Spotify.
  void _consumeQueuedAhead(int index) {
    final previous = _lastIndex;
    _lastIndex = index;
    if (previous == null || _queuedAhead == 0) return;
    final order = _playOrder.length == _items.length ? _playOrder : null;
    final from = order?.indexOf(previous) ?? previous;
    final to = order?.indexOf(index) ?? index;
    _queuedAhead = to > from ? max(0, _queuedAhead - (to - from)) : 0;
  }

  void _refreshPlayOrder() {
    _playOrder = _player.shuffleModeEnabled
        ? List.unmodifiable(_player.shuffleIndices)
        : const [];
  }

  void _beginItem(
    domain.AuthSession session,
    domain.LibraryItem item,
    int generation,
  ) {
    mediaItem.add(_toMediaItem(item));
    unawaited(_resolveArtwork(session, item, generation));
    _reportedItem = item;
    _reportedPosition = Duration.zero;
    _playSessionId = const Uuid().v4();
  }

  // Non-positional state last sent to the platform; position between pushes
  // is interpolated by audio_service from updatePosition and its timestamp.
  (bool, ProcessingState, int?, LoopMode, bool, double)? _lastPlatformState;

  void _updateSnapshot({bool forcePlatformUpdate = false}) {
    final index = _player.currentIndex ?? (_items.isEmpty ? -1 : 0);
    final repeatMode = switch (_player.loopMode) {
      LoopMode.one => domain.RepeatMode.one,
      LoopMode.all => domain.RepeatMode.all,
      LoopMode.off => domain.RepeatMode.off,
    };
    _snapshot = domain.PlaybackSnapshot(
      queue: domain.PlaybackQueue(
        items: _items,
        currentIndex: index,
        shuffle: _player.shuffleModeEnabled,
        repeatMode: repeatMode,
        playOrder: _playOrder,
      ),
      position: _player.position,
      bufferedPosition: _player.bufferedPosition,
      playing: _player.playing,
      buffering:
          _player.processingState == ProcessingState.loading ||
          _player.processingState == ProcessingState.buffering,
      volume: _player.volume,
      sleepDeadline: _snapshot.sleepDeadline,
    );
    if (!_snapshots.isClosed) _snapshots.add(_snapshot);
    final platformState = (
      _player.playing,
      _player.processingState,
      _player.currentIndex,
      _player.loopMode,
      _player.shuffleModeEnabled,
      _player.speed,
    );
    if (!forcePlatformUpdate && platformState == _lastPlatformState) return;
    _lastPlatformState = platformState;
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: switch (_player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: index < 0 ? null : index,
        repeatMode: switch (repeatMode) {
          domain.RepeatMode.off => AudioServiceRepeatMode.none,
          domain.RepeatMode.all => AudioServiceRepeatMode.all,
          domain.RepeatMode.one => AudioServiceRepeatMode.one,
        },
        shuffleMode: _player.shuffleModeEnabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
      ),
    );
  }

  /// Maps the streaming-quality setting to a transcode bitrate cap;
  /// null lets the server send the original stream.
  Future<int?> _preferredBitrate() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString('streamQuality')) {
      'High' => 320000,
      'Data saver' => 128000,
      _ => null,
    };
  }

  Future<List<AudioSource>> _createSources(
    domain.AuthSession session,
    List<domain.LibraryItem> items,
  ) async {
    final maxBitrate = await _preferredBitrate();
    var localPaths = const <String, String>{};
    try {
      localPaths =
          await _localSourceResolver?.call(session.profile.profileId) ??
          const {};
    } catch (error) {
      appLog.warning('Downloaded tracks unavailable, streaming: $error');
    }
    return [
      for (final item in items)
        if (localPaths[item.id] case final path?)
          AudioSource.uri(Uri.file(path), tag: _toMediaItem(item))
        else
          AudioSource.uri(
            _gateway.streamUri(session, item, maxBitrate: maxBitrate),
            headers: _gateway.playbackHeaders(session),
            tag: _toMediaItem(item),
          ),
    ];
  }

  @override
  Future<void> restore(
    domain.AuthSession session,
    List<domain.LibraryItem> library,
  ) async {
    final database = _database;
    if (database == null) return;
    await setBrowseLibrary(session, library);
    final profileId = session.profile.profileId;
    final rows = await database.queueFor(profileId);
    final saved = await database.playbackStateFor(profileId);
    final byId = {for (final item in library) item.id: item};
    // Map the saved index through any tracks that have left the library.
    var index = 0;
    final restored = <domain.LibraryItem>[];
    for (final row in rows) {
      final item = byId[row.itemId];
      if (item == null) continue;
      if (row.queueIndex == saved?.currentIndex) index = restored.length;
      restored.add(item);
    }
    if (restored.isEmpty) return;
    await _loadQueue(
      session,
      restored,
      initialIndex: index,
      autoPlay: false,
      shuffle: saved?.shuffle ?? false,
      initialPosition: Duration(milliseconds: saved?.positionMs ?? 0),
    );
    _queueDirty = false;
    final repeat = domain.RepeatMode.values.firstWhere(
      (value) => value.name == saved?.repeatMode,
      orElse: () => domain.RepeatMode.off,
    );
    await setRepeat(repeat);
    final deadline = saved?.sleepDeadline;
    if (deadline != null && deadline.isAfter(DateTime.now())) {
      await setSleepTimer(deadline.difference(DateTime.now()));
    }
  }

  @override
  Future<void> setBrowseLibrary(
    domain.AuthSession session,
    List<domain.LibraryItem> library,
  ) async {
    if (_session == null ||
        _session?.profile.profileId == session.profile.profileId) {
      _session = session;
      _browseLibrary = List.unmodifiable(library);
    }
  }

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    if (parentMediaId == AudioService.recentRootId) {
      final current = _reportedItem;
      return current == null ? const [] : [_toMediaItem(current)];
    }
    if (parentMediaId == AudioService.browsableRootId) {
      return const [
        MediaItem(id: 'category:albums', title: 'Albums', playable: false),
        MediaItem(id: 'category:artists', title: 'Artists', playable: false),
        MediaItem(id: 'category:songs', title: 'Songs', playable: false),
        MediaItem(
          id: 'category:playlists',
          title: 'Playlists',
          playable: false,
        ),
        MediaItem(id: 'category:genres', title: 'Genres', playable: false),
        MediaItem(id: 'category:liked', title: 'Liked Songs', playable: false),
        MediaItem(
          id: 'category:downloads',
          title: 'Downloads',
          playable: false,
        ),
      ];
    }
    if (!parentMediaId.startsWith('category:')) return const [];
    final category = parentMediaId.substring('category:'.length);
    Set<String> downloadedIds = const {};
    final session = _session;
    if (category == 'downloads' && session != null) {
      final paths = await _localSourceResolver?.call(session.profile.profileId);
      downloadedIds = paths?.keys.toSet() ?? const {};
    }
    final selected = _browseLibrary
        .where((item) {
          return switch (category) {
            'albums' => item.type == domain.LibraryItemType.album,
            'artists' => item.type == domain.LibraryItemType.artist,
            'songs' => item.type == domain.LibraryItemType.track,
            'playlists' => item.type == domain.LibraryItemType.playlist,
            'genres' => item.type == domain.LibraryItemType.genre,
            'liked' =>
              item.type == domain.LibraryItemType.track && item.isFavorite,
            'downloads' => downloadedIds.contains(item.id),
            _ => false,
          };
        })
        .take(500);
    return selected.map(_toBrowsableMediaItem).toList(growable: false);
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    final id = mediaId.startsWith('item:') ? mediaId.substring(5) : mediaId;
    final item = _browseLibrary.where((entry) => entry.id == id).firstOrNull;
    return item == null ? null : _toBrowsableMediaItem(item);
  }

  @override
  Future<List<MediaItem>> search(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];
    return _browseLibrary
        .where(
          (item) => '${item.name} ${item.subtitle ?? ''}'
              .toLowerCase()
              .contains(normalized),
        )
        .take(100)
        .map(_toBrowsableMediaItem)
        .toList(growable: false);
  }

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    final session = _session;
    if (session == null) return;
    final id = mediaId.startsWith('item:') ? mediaId.substring(5) : mediaId;
    final selected = _browseLibrary.where((item) => item.id == id).firstOrNull;
    if (selected == null) return;
    if (selected.type == domain.LibraryItemType.track) {
      // Queue the track's album around it rather than the whole library.
      final album =
          _browseLibrary
              .where(
                (item) =>
                    item.type == domain.LibraryItemType.track &&
                    item.albumId != null &&
                    item.albumId == selected.albumId,
              )
              .toList()
            ..sort(domain.compareTrackOrder);
      final tracks = album.any((item) => item.id == selected.id)
          ? album
          : [selected];
      await load(
        session,
        tracks,
        initialIndex: tracks.indexWhere((item) => item.id == selected.id),
      );
      return;
    }
    final tracks = await _tracksFor?.call(session, selected) ?? const [];
    if (tracks.isNotEmpty) await load(session, tracks);
  }

  @override
  Future<void> persistNow() async {
    _persistTimer?.cancel();
    _persistTimer = null;
    await _persist();
  }

  /// Throttled, not debounced: position updates arrive several times a
  /// second, and a debounce would never fire while music plays.
  void _schedulePersist() {
    if (_database == null || _session == null || _items.isEmpty) return;
    _persistTimer ??= Timer(_persistDelay, () {
      _persistTimer = null;
      unawaited(_persist());
    });
  }

  Future<void> _persist() async {
    final database = _database;
    final session = _session;
    if (database == null || session == null || _items.isEmpty) return;
    final profileId = session.profile.profileId;
    final state = db.PlaybackStatesCompanion.insert(
      profileId: profileId,
      currentIndex: Value(_player.currentIndex ?? -1),
      positionMs: Value(_player.position.inMilliseconds),
      shuffle: Value(_player.shuffleModeEnabled),
      repeatMode: Value(_snapshot.queue.repeatMode.name),
      sleepDeadline: Value(_snapshot.sleepDeadline),
    );
    final writeQueue = _queueDirty;
    _queueDirty = false;
    try {
      if (writeQueue) {
        await database.replaceQueue(profileId, [
          for (var index = 0; index < _items.length; index++)
            db.QueueEntriesCompanion.insert(
              profileId: profileId,
              queueIndex: index,
              itemId: _items[index].id,
              isCurrent: Value(index == _player.currentIndex),
            ),
        ], state);
      } else {
        await database.savePlaybackState(state);
      }
    } catch (error) {
      if (writeQueue) _queueDirty = true;
      appLog.warning('Playback state could not be saved: $error');
    }
  }

  MediaItem _toMediaItem(domain.LibraryItem item) {
    return MediaItem(
      id: item.id,
      album: item.albumName,
      title: item.name,
      artist: item.subtitle,
      duration: item.duration,
      artUri: _localArtwork['${item.profileId}:${item.id}'],
      extras: {'profileId': item.profileId, 'serverId': item.serverId},
    );
  }

  Future<void> _resolveArtwork(
    domain.AuthSession session,
    domain.LibraryItem item,
    int generation,
  ) async {
    final resolver = _artworkResolver;
    if (resolver == null || item.imageUrl == null) return;
    try {
      final uri = await resolver(session, item);
      if (uri == null ||
          generation != _loadGeneration ||
          _session?.profile.profileId != session.profile.profileId) {
        return;
      }
      _localArtwork['${item.profileId}:${item.id}'] = uri;
      final index = _items.indexWhere(
        (entry) => entry.profileId == item.profileId && entry.id == item.id,
      );
      if (index >= 0) {
        final mediaItems = _items.map(_toMediaItem).toList(growable: false);
        queue.add(mediaItems);
        if (_player.currentIndex == index) mediaItem.add(mediaItems[index]);
      }
    } catch (error) {
      appLog.fine('Artwork cache unavailable for system controls: $error');
    }
  }

  Future<void> _reportStarted() async {
    final session = _session;
    final item = _reportedItem;
    if (session == null || item == null) return;
    try {
      await _reporter.reportPlaybackStarted(
        session,
        item,
        playSessionId: _playSessionId,
      );
    } catch (error) {
      appLog.warning('Playback start report deferred: $error');
    }
    try {
      await _database?.markDownloadPlayed(session.profile.profileId, item.id);
    } catch (error) {
      appLog.fine('Download play time not recorded: $error');
    }
  }

  Future<void> _reportProgress() async {
    if (_reportInFlight) return;
    final session = _session;
    final item = _reportedItem;
    if (session == null || item == null) return;
    _reportInFlight = true;
    try {
      await _reporter.reportPlaybackProgress(
        session,
        item,
        _player.position,
        paused: !_player.playing,
        playSessionId: _playSessionId,
      );
    } catch (error) {
      appLog.warning('Playback progress report deferred: $error');
    } finally {
      _reportInFlight = false;
    }
  }

  MediaItem _toBrowsableMediaItem(domain.LibraryItem item) {
    final track = item.type == domain.LibraryItemType.track;
    final base = _toMediaItem(item);
    return base.copyWith(
      id: 'item:${item.id}',
      playable: track,
      extras: {...?base.extras, 'browsable': !track},
    );
  }

  Future<void> _reportStopped() async {
    final session = _session;
    final item = _reportedItem;
    final position = _reportedPosition;
    final playSessionId = _playSessionId;
    final started = !_startReportPending;
    if (session == null || item == null) return;
    _reportedItem = null;
    _playSessionId = null;
    // Never report a stop for a restored track Jellyfin never saw start.
    if (!started) return;
    try {
      await _reporter.reportPlaybackStopped(
        session,
        item,
        position,
        playSessionId: playSessionId,
      );
    } catch (error) {
      appLog.warning('Playback stop report deferred: $error');
    }
  }
}
