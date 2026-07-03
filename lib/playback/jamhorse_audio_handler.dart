import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:jamhorse/core/logging.dart';
import 'package:jamhorse/domain/contracts.dart';
import 'package:jamhorse/domain/models.dart' as domain;
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Returns a playable local file path for a downloaded track, or null to
/// stream it from the server.
typedef LocalSourceResolver =
    Future<String?> Function(domain.LibraryItem item);

class JamHorseAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler
    implements PlaybackCoordinator {
  JamHorseAudioHandler(
    this._gateway, {
    AudioPlayer? player,
    this._localSourceResolver,
  }) : _player = player ?? AudioPlayer() {
    _bindPlayer();
  }

  final JellyfinGateway _gateway;
  final AudioPlayer _player;
  final LocalSourceResolver? _localSourceResolver;
  final _snapshots = StreamController<domain.PlaybackSnapshot>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];

  domain.AuthSession? _session;
  List<domain.LibraryItem> _items = const [];
  domain.PlaybackSnapshot _snapshot = const domain.PlaybackSnapshot();
  Timer? _reportTimer;

  Future<void> initialize() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _reportTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(_reportProgress()),
    );
  }

  @override
  domain.PlaybackSnapshot get currentSnapshot => _snapshot;

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
    await _reportStopped();
    _session = session;
    _items = List.unmodifiable(queueItems);

    final mediaItems = queueItems.map(_toMediaItem).toList(growable: false);
    queue.add(mediaItems);
    final maxBitrate = await _preferredBitrate();
    final sources = <AudioSource>[];
    for (final item in queueItems) {
      final localPath = await _localSourceResolver?.call(item);
      sources.add(
        localPath != null
            ? AudioSource.uri(Uri.file(localPath), tag: _toMediaItem(item))
            : AudioSource.uri(
                _gateway.streamUri(session, item, maxBitrate: maxBitrate),
                headers: _gateway.playbackHeaders(session),
                tag: _toMediaItem(item),
              ),
      );
    }
    await _player.setAudioSources(
      sources,
      initialIndex: initialIndex.clamp(0, queueItems.length - 1),
      initialPosition: Duration.zero,
      preload: true,
    );
    _updateSnapshot();
    await _gateway.reportPlaybackStarted(session, _items[initialIndex]);
    if (autoPlay) await play();
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
    await _reportStopped();
    if (_player.hasNext) {
      await _player.seekToNext();
      await _reportStarted();
    }
  }

  @override
  Future<void> skipToNext() => skipNext();

  @override
  Future<void> skipPrevious() async {
    if (_player.position > const Duration(seconds: 4)) {
      return seek(Duration.zero);
    }
    await _reportStopped();
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      await _reportStarted();
    } else {
      await seek(Duration.zero);
    }
  }

  @override
  Future<void> skipToPrevious() => skipPrevious();

  @override
  Future<void> setShuffle(bool enabled) async {
    if (enabled) await _player.shuffle();
    await _player.setShuffleModeEnabled(enabled);
    _updateSnapshot();
  }

  @override
  Future<void> setRepeat(domain.RepeatMode mode) async {
    await _player.setLoopMode(
      switch (mode) {
        domain.RepeatMode.off => LoopMode.off,
        domain.RepeatMode.all => LoopMode.all,
        domain.RepeatMode.one => LoopMode.one,
      },
    );
    _updateSnapshot();
  }

  @override
  Future<void> setVolume(double volume) {
    return _player.setVolume(volume.clamp(0, 1));
  }

  @override
  Future<void> stop() async {
    await _reportStopped();
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) {
    return setRepeat(
      switch (repeatMode) {
        AudioServiceRepeatMode.one => domain.RepeatMode.one,
        AudioServiceRepeatMode.all ||
        AudioServiceRepeatMode.group => domain.RepeatMode.all,
        _ => domain.RepeatMode.off,
      },
    );
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) {
    return setShuffle(shuffleMode != AudioServiceShuffleMode.none);
  }

  void _bindPlayer() {
    _subscriptions
      ..add(_player.playerStateStream.listen((_) => _updateSnapshot()))
      ..add(_player.positionStream.listen((_) => _updateSnapshot()))
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
    if (index == null || index < 0 || index >= _items.length) return;
    mediaItem.add(_toMediaItem(_items[index]));
    await _reportStarted();
    _updateSnapshot();
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

  MediaItem _toMediaItem(domain.LibraryItem item) {
    return MediaItem(
      id: item.id,
      album: item.type == domain.LibraryItemType.track ? item.subtitle : null,
      title: item.name,
      artist: item.subtitle,
      duration: item.duration,
      artUri: item.imageUrl,
      extras: {'serverId': item.serverId},
    );
  }

  Future<void> _reportStarted() async {
    final session = _session;
    final item = currentSnapshot.queue.current;
    if (session == null || item == null) return;
    try {
      await _gateway.reportPlaybackStarted(session, item);
    } catch (error) {
      appLog.warning('Playback start report deferred: $error');
    }
  }

  Future<void> _reportProgress() async {
    final session = _session;
    final item = currentSnapshot.queue.current;
    if (session == null || item == null) return;
    try {
      await _gateway.reportPlaybackProgress(
        session,
        item,
        _player.position,
        paused: !_player.playing,
      );
    } catch (error) {
      appLog.warning('Playback progress report deferred: $error');
    }
  }

  Future<void> _reportStopped() async {
    final session = _session;
    final item = currentSnapshot.queue.current;
    if (session == null || item == null) return;
    try {
      await _gateway.reportPlaybackStopped(session, item, _player.position);
    } catch (error) {
      appLog.warning('Playback stop report deferred: $error');
    }
  }

  Future<void> disposeHandler() async {
    _reportTimer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    await _snapshots.close();
  }
}
