import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/domain/contracts.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/library_index.dart';
import 'package:jamhorse/state/providers.dart';

final castConnectedProvider = Provider<bool>((ref) {
  final bridge = ref.watch(platformMediaBridgeProvider);
  final capabilities =
      ref.watch(platformCapabilitiesProvider).value ?? bridge.capabilities;
  return capabilities.castConnected;
});

/// The snapshot of whichever player is audible: the local handler, or the
/// Cast receiver while casting. Changes on every position tick, so widgets
/// should watch the narrower providers below instead.
final activePlaybackProvider = Provider<PlaybackSnapshot>((ref) {
  final coordinator = ref.watch(playbackCoordinatorProvider);
  final local =
      ref.watch(playbackSnapshotProvider).value ?? coordinator.currentSnapshot;
  if (!ref.watch(castConnectedProvider)) return local;
  final bridge = ref.watch(platformMediaBridgeProvider);
  final remote =
      ref.watch(remotePlaybackProvider).value ?? bridge.remoteSession;
  final queue = local.queue;
  final remoteIndex = remote.itemId == null
      ? -1
      : queue.items.indexWhere((item) => item.id == remote.itemId);
  return PlaybackSnapshot(
    queue: remoteIndex < 0 || remoteIndex == queue.currentIndex
        ? queue
        : PlaybackQueue(
            items: queue.items,
            currentIndex: remoteIndex,
            shuffle: queue.shuffle,
            repeatMode: queue.repeatMode,
            playOrder: queue.playOrder,
          ),
    position: remote.position,
    playing: remote.playing,
    buffering: remote.buffering,
    volume: local.volume,
    sleepDeadline: local.sleepDeadline,
  );
});

final playbackQueueProvider = Provider<PlaybackQueue>((ref) {
  return ref.watch(activePlaybackProvider.select((state) => state.queue));
});

final playbackPlayingProvider = Provider<bool>((ref) {
  return ref.watch(activePlaybackProvider.select((state) => state.playing));
});

final playbackPositionProvider = Provider<Duration>((ref) {
  return ref.watch(activePlaybackProvider.select((state) => state.position));
});

final playbackVolumeProvider = Provider<double>((ref) {
  return ref.watch(activePlaybackProvider.select((state) => state.volume));
});

final sleepDeadlineProvider = Provider<DateTime?>((ref) {
  return ref.watch(
    activePlaybackProvider.select((state) => state.sleepDeadline),
  );
});

/// The playing track, with its liked state kept in sync with the library
/// (the queue holds a copy made when playback started).
final currentTrackProvider = Provider<LibraryItem?>((ref) {
  final item = ref.watch(
    activePlaybackProvider.select((state) => state.queue.current),
  );
  if (item == null) return null;
  final live = ref.watch(libraryIndexProvider).byId[item.id];
  if (live == null || live.isFavorite == item.isFavorite) return item;
  return item.copyWith(isFavorite: live.isFavorite);
});

final playerControllerProvider = Provider<PlayerController>(
  PlayerController.new,
);

/// Transport commands routed to the audible player, so no widget has to
/// branch on whether a Cast session is active.
class PlayerController {
  PlayerController(this._ref);

  final Ref _ref;

  PlaybackCoordinator get _local => _ref.read(playbackCoordinatorProvider);
  PlatformMediaBridge get _bridge => _ref.read(platformMediaBridgeProvider);

  bool get casting => _ref.read(castConnectedProvider);

  Future<void> play() => casting ? _bridge.remotePlay() : _local.play();

  Future<void> pause() => casting ? _bridge.remotePause() : _local.pause();

  Future<void> togglePlay() {
    return _ref.read(playbackPlayingProvider) ? pause() : play();
  }

  Future<void> next() => casting ? _bridge.remoteNext() : _local.skipNext();

  Future<void> previous() {
    return casting ? _bridge.remotePrevious() : _local.skipPrevious();
  }

  Future<void> seek(Duration position) {
    return casting ? _bridge.remoteSeek(position) : _local.seek(position);
  }

  Future<void> setVolume(double volume) => _local.setVolume(volume);

  // Queue shape is owned by the local player; the Cast receiver plays the
  // queue it was handed, so these are no-ops while casting.

  Future<void> toggleShuffle() async {
    if (casting) return;
    await _local.setShuffle(!_ref.read(playbackQueueProvider).shuffle);
  }

  Future<void> cycleRepeat() async {
    if (casting) return;
    await _local.setRepeat(switch (_ref
        .read(playbackQueueProvider)
        .repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    });
  }

  Future<void> skipToIndex(int index) async {
    if (!casting) await _local.skipToIndex(index);
  }

  Future<void> moveQueueItem(int from, int to) async {
    if (!casting) await _local.moveQueueItem(from, to);
  }

  Future<void> removeQueueItemAt(int index) async {
    if (!casting) await _local.removeQueueItemAt(index);
  }
}
