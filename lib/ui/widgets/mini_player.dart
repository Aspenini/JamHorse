import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';

/// Spotify-style full-width playback bar shown at the bottom of the
/// desktop layout.
class PlayerBar extends ConsumerWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinator = ref.watch(playbackCoordinatorProvider);
    final snapshot =
        ref.watch(playbackSnapshotProvider).value ??
        coordinator.currentSnapshot;
    final item = snapshot.queue.current;
    if (item == null) return const SizedBox.shrink();
    // The queue holds a frozen copy, so read live favorite state from the
    // synced library when available.
    final library = ref.watch(
      appControllerProvider.select((state) => state.library),
    );
    final live =
        library.firstWhereOrNull((entry) => entry.id == item.id) ?? item;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0B0F1A),
        border: Border(top: BorderSide(color: Color(0xFF1B2130))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 56,
                  child: Artwork(item: item, borderRadius: 8, iconSize: 24),
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
                  icon: Icon(
                    live.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                    color: live.isFavorite ? JamColors.accentBright : null,
                  ),
                ),
              ],
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
                      onPressed: () =>
                          coordinator.setShuffle(!snapshot.queue.shuffle),
                      color: snapshot.queue.shuffle
                          ? JamColors.accentBright
                          : JamColors.muted,
                      icon: const Icon(Icons.shuffle_rounded, size: 20),
                    ),
                    IconButton(
                      tooltip: 'Previous',
                      visualDensity: VisualDensity.compact,
                      onPressed: coordinator.skipPrevious,
                      icon: const Icon(Icons.skip_previous_rounded, size: 28),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: IconButton.filled(
                        tooltip: snapshot.playing ? 'Pause' : 'Play',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: JamColors.ink,
                        ),
                        onPressed: snapshot.playing
                            ? coordinator.pause
                            : coordinator.play,
                        icon: Icon(
                          snapshot.playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next',
                      visualDensity: VisualDensity.compact,
                      onPressed: coordinator.skipNext,
                      icon: const Icon(Icons.skip_next_rounded, size: 28),
                    ),
                    IconButton(
                      tooltip: 'Repeat',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        final next = switch (snapshot.queue.repeatMode) {
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
                        onSeek: coordinator.seek,
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
                  icon: const Icon(Icons.open_in_full_rounded, size: 18),
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
    final snapshot =
        ref.watch(playbackSnapshotProvider).value ??
        coordinator.currentSnapshot;
    final item = snapshot.queue.current;
    if (item == null) return const SizedBox.shrink();
    final duration = item.duration.inMilliseconds.toDouble();
    final progress =
        (duration <= 0
                ? 0.0
                : (snapshot.position.inMilliseconds / duration).clamp(0, 1))
            .toDouble();
    return Semantics(
      button: true,
      label: 'Now playing ${item.name}',
      child: Material(
        color: const Color(0xF5121724),
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          onTap: () => context.push('/now-playing'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                color: JamColors.accent,
                backgroundColor: Colors.white12,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 48,
                      child: Artwork(
                        item: item,
                        borderRadius: 9,
                        iconSize: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
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
                    IconButton.filled(
                      tooltip: snapshot.playing ? 'Pause' : 'Play',
                      onPressed: snapshot.playing
                          ? coordinator.pause
                          : coordinator.play,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: JamColors.ink,
                      ),
                      icon: Icon(
                        snapshot.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next',
                      onPressed: coordinator.skipNext,
                      icon: const Icon(Icons.skip_next_rounded),
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
}
