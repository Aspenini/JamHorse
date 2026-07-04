import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:jamhorse/core/logging.dart';
import 'package:jamhorse/data/database.dart' as db;
import 'package:jamhorse/domain/contracts.dart';
import 'package:jamhorse/domain/models.dart' as domain;
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Returns a playable local file path for a downloaded track, or null to
/// stream it from the server.
typedef LocalSourceResolver = Future<String?> Function(domain.LibraryItem item);
typedef ArtworkResolver =
    Future<Uri?> Function(domain.AuthSession session, domain.LibraryItem item);

class JamHorseAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler
    implements PlaybackCoordinator {
  JamHorseAudioHandler(
    this._gateway, {
    AudioPlayer? player,
    this._localSourceResolver,
    this._artworkResolver,
    db.AppDatabase? database,
  }) : _player = player ?? AudioPlayer() {
    _database = database;
    _bindPlayer();
  }

  final JellyfinGateway _gateway;
  final AudioPlayer _player;
  final LocalSourceResolver? _localSourceResolver;
  final ArtworkResolver? _artworkResolver;
  late final db.AppDatabase? _database;
  final _snapshots = StreamController<domain.PlaybackSnapshot>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];

  domain.AuthSession? _session;
  List<domain.LibraryItem> _items = const [];
  List<domain.LibraryItem> _browseLibrary = const [];
  final _localArtwork = <String, Uri>{};
  domain.PlaybackSnapshot _snapshot = const domain.PlaybackSnapshot();
  Timer? _reportTimer;
  Timer? _sleepTimer;
  Timer? _persistTimer;
  bool _reportInFlight = false;
  bool _loading = false;
  int _loadGeneration = 0;
  domain.LibraryItem? _reportedItem;
  Duration _reportedPosition = Duration.zero;
  String? _playSessionId;
  Future<void> _transitionSerial = Future.value();

  Future<void> initialize() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _reportTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_reportInFlight) unawaited(_reportProgress());
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
  }) async {
    if (queueItems.isEmpty) return;
    final generation = ++_loadGeneration;
    await _reportStopped();
    if (generation != _loadGeneration) return;
    _loading = true;
    _session = session;
    _items = List.unmodifiable(queueItems);

    try {
      final mediaItems = queueItems.map(_toMediaItem).toList(growable: false);
      queue.add(mediaItems);
      final maxBitrate = await _preferredBitrate();
      if (generation != _loadGeneration) return;
      final sources = <AudioSource>[];
      for (final item in queueItems) {
        sources.add(await _createSource(session, item, maxBitrate));
        if (generation != _loadGeneration) return;
      }
      final safeIndex = initialIndex.clamp(0, queueItems.length - 1);
      await _player.setAudioSources(
        sources,
        initialIndex: safeIndex,
        initialPosition: Duration.zero,
        preload: autoPlay,
      );
      if (generation != _loadGeneration) return;
      _updateSnapshot();
      mediaItem.add(_toMediaItem(_items[safeIndex]));
      unawaited(_resolveArtwork(session, _items[safeIndex], generation));
      _reportedItem = _items[safeIndex];
      _reportedPosition = Duration.zero;
      _playSessionId = const Uuid().v4();
      await _reportStarted();
      if (generation != _loadGeneration) return;
      await _database?.markDownloadPlayed(
        session.profile.profileId,
        _items[safeIndex].id,
      );
      if (generation != _loadGeneration) return;
      _schedulePersist();
      if (autoPlay) await play();
    } finally {
      if (generation == _loadGeneration) _loading = false;
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() async {
    await _player.pause();
    await _reportProgress();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
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
    queue.add(_items.map(_toMediaItem).toList(growable: false));
    _updateSnapshot();
    _schedulePersist();
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    if (index < 0 || index >= _items.length || _items.length == 1) return;
    final mutable = _items.toList()..removeAt(index);
    _items = List.unmodifiable(mutable);
    await _player.removeAudioSourceAt(index);
    queue.add(_items.map(_toMediaItem).toList(growable: false));
    _updateSnapshot();
    _schedulePersist();
  }

  @override
  Future<void> setShuffle(bool enabled) async {
    if (enabled) await _player.shuffle();
    await _player.setShuffleModeEnabled(enabled);
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
    final deadline = duration == null ? null : DateTime.now().add(duration);
    _snapshot = domain.PlaybackSnapshot(
      queue: _snapshot.queue,
      position: _snapshot.position,
      bufferedPosition: _snapshot.bufferedPosition,
      playing: _snapshot.playing,
      buffering: _snapshot.buffering,
      volume: _snapshot.volume,
      sleepDeadline: deadline,
    );
    if (duration != null) {
      _sleepTimer = Timer(duration, () async {
        await pause();
        await setSleepTimer(null);
      });
    }
    _snapshots.add(_snapshot);
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
    _schedulePersist();
  }

  @override
  Future<void> stop() async {
    _loadGeneration++;
    _loading = false;
    await _reportStopped();
    await _player.stop();
    return super.stop();
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
          }
        }),
      )
      ..add(
        _player.positionStream.listen((position) {
          _reportedPosition = position;
          _updateSnapshot();
          _schedulePersist();
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
    _transitionSerial = _transitionSerial.then((_) async {
      if (_reportedItem?.id == _items[index].id &&
          _reportedItem?.profileId == _items[index].profileId) {
        _updateSnapshot();
        return;
      }
      await _reportStopped();
      _updateSnapshot();
      mediaItem.add(_toMediaItem(_items[index]));
      final session = _session;
      if (session != null) {
        unawaited(_resolveArtwork(session, _items[index], _loadGeneration));
      }
      _reportedItem = _items[index];
      _reportedPosition = Duration.zero;
      _playSessionId = const Uuid().v4();
      await _reportStarted();
      if (session != null) {
        await _database?.markDownloadPlayed(
          session.profile.profileId,
          _items[index].id,
        );
      }
      _schedulePersist();
    });
    await _transitionSerial;
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

  Future<AudioSource> _createSource(
    domain.AuthSession session,
    domain.LibraryItem item,
    int? maxBitrate,
  ) async {
    final localPath = await _localSourceResolver?.call(item);
    return localPath != null
        ? AudioSource.uri(Uri.file(localPath), tag: _toMediaItem(item))
        : AudioSource.uri(
            _gateway.streamUri(session, item, maxBitrate: maxBitrate),
            headers: _gateway.playbackHeaders(session),
            tag: _toMediaItem(item),
          );
  }

  @override
  Future<void> restore(
    domain.AuthSession session,
    List<domain.LibraryItem> library,
  ) async {
    final database = _database;
    if (database == null) return;
    await setBrowseLibrary(session, library);
    final rows = await database.queueFor(session.profile.profileId);
    final byId = {for (final item in library) item.id: item};
    final restored = [
      for (final row in rows)
        if (byId[row.itemId] != null) byId[row.itemId]!,
    ];
    if (restored.isEmpty) return;
    final saved = await database.playbackStateFor(session.profile.profileId);
    final index = (saved?.currentIndex ?? 0).clamp(0, restored.length - 1);
    await load(session, restored, initialIndex: index, autoPlay: false);
    final position = Duration(milliseconds: saved?.positionMs ?? 0);
    if (position > Duration.zero) await _player.seek(position);
    if (saved?.shuffle ?? false) await setShuffle(true);
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
    if (category == 'downloads' && _database != null && _session != null) {
      final downloads = await _database.allDownloads();
      downloadedIds = downloads
          .where(
            (entry) =>
                entry.profileId == _session!.profile.profileId &&
                entry.status == 'complete',
          )
          .map((entry) => entry.itemId)
          .toSet();
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
      final tracks = _browseLibrary
          .where((item) => item.type == domain.LibraryItemType.track)
          .toList(growable: false);
      await load(
        session,
        tracks,
        initialIndex: tracks.indexWhere((item) => item.id == selected.id),
      );
      return;
    }
    final tracks = await _gateway.fetchLibrary(
      session,
      types: const {domain.LibraryItemType.track},
      parentId: selected.id,
      sortBy: 'ParentIndexNumber,IndexNumber,SortName',
      limit: 5000,
    );
    if (tracks.isNotEmpty) await load(session, tracks);
  }

  void _schedulePersist() {
    if (_database == null || _session == null || _items.isEmpty) return;
    _persistTimer?.cancel();
    _persistTimer = Timer(
      const Duration(seconds: 1),
      () => unawaited(_persistQueue()),
    );
  }

  Future<void> _persistQueue() async {
    final database = _database;
    final session = _session;
    if (database == null || session == null || _items.isEmpty) return;
    final profileId = session.profile.profileId;
    await database.replaceQueue(
      profileId,
      [
        for (var index = 0; index < _items.length; index++)
          db.QueueEntriesCompanion.insert(
            profileId: profileId,
            queueIndex: index,
            itemId: _items[index].id,
            isCurrent: Value(index == _player.currentIndex),
          ),
      ],
      db.PlaybackStatesCompanion.insert(
        profileId: profileId,
        currentIndex: Value(_player.currentIndex ?? -1),
        positionMs: Value(_player.position.inMilliseconds),
        shuffle: Value(_player.shuffleModeEnabled),
        repeatMode: Value(_snapshot.queue.repeatMode.name),
        sleepDeadline: Value(_snapshot.sleepDeadline),
      ),
    );
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
      await _gateway.reportPlaybackStarted(
        session,
        item,
        playSessionId: _playSessionId,
      );
    } catch (error) {
      appLog.warning('Playback start report deferred: $error');
    }
  }

  Future<void> _reportProgress() async {
    if (_reportInFlight) return;
    final session = _session;
    final item = _reportedItem;
    if (session == null || item == null) return;
    _reportInFlight = true;
    try {
      await _gateway.reportPlaybackProgress(
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
    return _toMediaItem(item).copyWith(
      id: 'item:${item.id}',
      playable: track,
      extras: {...?_toMediaItem(item).extras, 'browsable': !track},
    );
  }

  Future<void> _reportStopped() async {
    final session = _session;
    final item = _reportedItem;
    final position = _reportedPosition;
    final playSessionId = _playSessionId;
    if (session == null || item == null) return;
    _reportedItem = null;
    _playSessionId = null;
    try {
      await _gateway.reportPlaybackStopped(
        session,
        item,
        position,
        playSessionId: playSessionId,
      );
    } catch (error) {
      appLog.warning('Playback stop report deferred: $error');
    }
  }

  Future<void> disposeHandler() async {
    _reportTimer?.cancel();
    _sleepTimer?.cancel();
    _persistTimer?.cancel();
    await _persistQueue();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    await _snapshots.close();
  }
}
