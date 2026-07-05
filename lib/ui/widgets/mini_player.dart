import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/contracts.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';
import 'package:jamhorse/ui/widgets/interaction.dart';

/// Spotify-style full-width playback bar shown at the bottom of the
/// desktop layout.
class PlayerBar extends ConsumerWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinator = ref.watch(playbackCoordinatorProvider);
    final bridge = ref.watch(platformMediaBridgeProvider);
    final snapshot = _effectiveSnapshot(ref, coordinator, bridge);
    final casting = bridge.capabilities.castConnected;
    final item = snapshot.queue.current;
    if (item == null) {
      return const SizedBox(
        height: 104,
        child: ColoredBox(
          color: JamColors.ink,
          child: Center(
            child: Text(
              'Choose something to play',
              style: TextStyle(color: JamColors.muted),
            ),
          ),
        ),
      );
    }
    // The queue holds a frozen copy, so read live favorite state from the
    // synced library when available.
    final library = ref.watch(
      appControllerProvider.select((state) => state.library),
    );
    final live =
        library.firstWhereOrNull((entry) => entry.id == item.id) ?? item;
    return SizedBox(
      height: 104,
      child: ColoredBox(
        color: JamColors.ink,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: EntranceMotion(
                  watchKey: item.id,
                  child: Row(
                    children: [
                      HoverScale(
                        hoverScale: 1.035,
                        child: SizedBox.square(
                          dimension: 64,
                          child: Artwork(
                            item: item,
                            borderRadius: 4,
                            iconSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              item.subtitle ?? 'Unknown artist',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: JamColors.muted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: live.isFavorite
                            ? 'Remove from Liked Songs'
                            : 'Add to Liked Songs',
                        onPressed: () => ref
                            .read(appControllerProvider.notifier)
                            .toggleFavorite(live),
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            live.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(live.isFavorite),
                            size: 20,
                            color: live.isFavorite
                                ? JamColors.accentBright
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'Shuffle',
                          visualDensity: VisualDensity.compact,
                          onPressed: casting
                              ? null
                              : () => coordinator.setShuffle(
                                  !snapshot.queue.shuffle,
                                ),
                          color: snapshot.queue.shuffle
                              ? JamColors.accentBright
                              : JamColors.muted,
                          icon: const Icon(Icons.shuffle_rounded, size: 20),
                        ),
                        IconButton(
                          tooltip: 'Previous',
                          visualDensity: VisualDensity.compact,
                          onPressed: casting
                              ? bridge.remotePrevious
                              : coordinator.skipPrevious,
                          icon: const Icon(
                            Icons.skip_previous_rounded,
                            size: 28,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: HoverScale(
                            hoverScale: 1.09,
                            child: IconButton.filled(
                              tooltip: snapshot.playing ? 'Pause' : 'Play',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                minimumSize: const Size.square(42),
                              ),
                              onPressed: snapshot.playing
                                  ? (casting
                                        ? bridge.remotePause
                                        : coordinator.pause)
                                  : (casting
                                        ? bridge.remotePlay
                                        : coordinator.play),
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 160),
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                child: Icon(
                                  snapshot.playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  key: ValueKey(snapshot.playing),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Next',
                          visualDensity: VisualDensity.compact,
                          onPressed: casting
                              ? bridge.remoteNext
                              : coordinator.skipNext,
                          icon: const Icon(Icons.skip_next_rounded, size: 28),
                        ),
                        IconButton(
                          tooltip: 'Repeat',
                          visualDensity: VisualDensity.compact,
                          onPressed: casting
                              ? null
                              : () {
                                  final next =
                                      switch (snapshot.queue.repeatMode) {
                                        RepeatMode.off => RepeatMode.all,
                                        RepeatMode.all => RepeatMode.one,
                                        RepeatMode.one => RepeatMode.off,
                                      };
                                  coordinator.setRepeat(next);
                                },
                          color: snapshot.queue.repeatMode == RepeatMode.off
                              ? JamColors.muted
                              : JamColors.accentBright,
                          icon: Icon(
                            snapshot.queue.repeatMode == RepeatMode.one
                                ? Icons.repeat_one_rounded
                                : Icons.repeat_rounded,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          _time(snapshot.position),
                          style: const TextStyle(
                            fontSize: 11,
                            color: JamColors.muted,
                          ),
                        ),
                        Expanded(
                          child: _BarSeekSlider(
                            position: snapshot.position,
                            duration: item.duration,
                            onSeek: casting
                                ? bridge.remoteSeek
                                : coordinator.seek,
                          ),
                        ),
                        Text(
                          _time(item.duration),
                          style: const TextStyle(
                            fontSize: 11,
                            color: JamColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Now playing',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => context.push('/now-playing'),
                      icon: const Icon(Icons.slideshow_outlined, size: 19),
                    ),
                    IconButton(
                      tooltip: 'Queue',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => context.push('/now-playing?tab=queue'),
                      icon: const Icon(Icons.queue_music_rounded, size: 20),
                    ),
                    const Icon(
                      Icons.volume_up_rounded,
                      size: 18,
                      color: JamColors.muted,
                    ),
                    SizedBox(
                      width: 110,
                      child: Slider(
                        value: snapshot.volume.clamp(0, 1),
                        onChanged: coordinator.setVolume,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _time(Duration value) {
    final safe = value.isNegative ? Duration.zero : value;
    final minutes = safe.inMinutes;
    final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _BarSeekSlider extends StatefulWidget {
  const _BarSeekSlider({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  @override
  State<_BarSeekSlider> createState() => _BarSeekSliderState();
}

class _BarSeekSliderState extends State<_BarSeekSlider> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final max = widget.duration.inMilliseconds.toDouble();
    final safeMax = max <= 0 ? 1.0 : max;
    final value = (_dragValue ?? widget.position.inMilliseconds.toDouble())
        .clamp(0.0, safeMax);
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
      ),
      child: Slider(
        value: value,
        max: safeMax,
        onChanged: (next) => setState(() => _dragValue = next),
        onChangeEnd: (next) {
          widget.onSeek(Duration(milliseconds: next.round()));
          _dragValue = null;
        },
      ),
    );
  }
}

/// Compact tap-to-expand player used above the navigation bar on
/// mobile-sized layouts.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinator = ref.watch(playbackCoordinatorProvider);
    final bridge = ref.watch(platformMediaBridgeProvider);
    final snapshot = _effectiveSnapshot(ref, coordinator, bridge);
    final casting = bridge.capabilities.castConnected;
    final item = snapshot.queue.current;
    if (item == null) return const SizedBox.shrink();
    final duration = item.duration.inMilliseconds.toDouble();
    final progress =
        (duration <= 0
                ? 0.0
                : (snapshot.position.inMilliseconds / duration).clamp(0, 1))
            .toDouble();
    // Spotify's phone mini player: a floating rounded card with a hairline
    // progress bar tucked inside its bottom edge.
    return Semantics(
      button: true,
      label: 'Now playing ${item.name}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
        child: Material(
          color: const Color(0xFF35333F),
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: () => context.push('/now-playing'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 4, 6),
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: 42,
                        child: Artwork(
                          item: item,
                          borderRadius: 6,
                          iconSize: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              item.subtitle ?? 'Unknown artist',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: JamColors.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: snapshot.playing ? 'Pause' : 'Play',
                        onPressed: snapshot.playing
                            ? (casting ? bridge.remotePause : coordinator.pause)
                            : (casting ? bridge.remotePlay : coordinator.play),
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        iconSize: 30,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          child: Icon(
                            snapshot.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            key: ValueKey(snapshot.playing),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next',
                        onPressed: casting
                            ? bridge.remoteNext
                            : coordinator.skipNext,
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        iconSize: 28,
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 7),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 2,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

PlaybackSnapshot _effectiveSnapshot(
  WidgetRef ref,
  PlaybackCoordinator coordinator,
  PlatformMediaBridge bridge,
) {
  final local =
      ref.watch(playbackSnapshotProvider).value ?? coordinator.currentSnapshot;
  if (!bridge.capabilities.castConnected) return local;
  final remote =
      ref.watch(remotePlaybackProvider).value ?? bridge.remoteSession;
  final remoteIndex = remote.itemId == null
      ? -1
      : local.queue.items.indexWhere((item) => item.id == remote.itemId);
  return PlaybackSnapshot(
    queue: PlaybackQueue(
      items: local.queue.items,
      currentIndex: remoteIndex >= 0 ? remoteIndex : local.queue.currentIndex,
      shuffle: local.queue.shuffle,
      repeatMode: local.queue.repeatMode,
    ),
    position: remote.position,
    playing: remote.playing,
    buffering: remote.buffering,
    volume: local.volume,
    sleepDeadline: local.sleepDeadline,
  );
}
