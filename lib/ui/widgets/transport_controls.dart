import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/core/format.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/library_index.dart';
import 'package:jamhorse/state/playback_providers.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/interaction.dart';

/// Heart toggle that reflects the library's live liked state.
class LikeButton extends ConsumerWidget {
  const LikeButton({
    required this.item,
    super.key,
    this.size = 20,
    this.onlyWhenLiked = false,
  });

  final LibraryItem item;
  final double size;

  /// Renders nothing unless liked, for rows that reveal the heart on hover.
  final bool onlyWhenLiked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(
      libraryIndexProvider.select(
        (index) => index.byId[item.id]?.isFavorite ?? item.isFavorite,
      ),
    );
    if (onlyWhenLiked && !liked) return const SizedBox.shrink();
    final destination = item.type == LibraryItemType.track
        ? 'Liked Songs'
        : 'Your Library';
    return IconButton(
      tooltip: liked ? 'Remove from $destination' : 'Save to $destination',
      iconSize: size,
      visualDensity: VisualDensity.compact,
      onPressed: () => ref
          .read(appControllerProvider.notifier)
          .toggleFavorite(item.copyWith(isFavorite: liked)),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(liked),
          color: liked ? JamColors.accentBright : null,
        ),
      ),
    );
  }
}

/// Round play/pause button for whatever is currently loaded.
class PlayPauseButton extends ConsumerWidget {
  const PlayPauseButton({super.key, this.size = 40, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(playbackPlayingProvider);
    return HoverScale(
      hoverScale: 1.06,
      child: IconButton.filled(
        tooltip: playing ? 'Pause' : 'Play',
        style: IconButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          fixedSize: Size.square(size),
          minimumSize: Size.square(size),
          padding: EdgeInsets.zero,
        ),
        iconSize: size * 0.6,
        onPressed: () => ref.read(playerControllerProvider).togglePlay(),
        icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
      ),
    );
  }
}

/// An icon toggle that turns green with a dot beneath it when active, like
/// Spotify's shuffle, repeat, queue, and lyrics buttons.
class ModeIconButton extends StatelessWidget {
  const ModeIconButton({
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.onPressed,
    super.key,
    this.size = 18,
    this.inactiveColor = JamColors.muted,
  });

  final String tooltip;
  final IconData icon;
  final bool active;
  final VoidCallback? onPressed;
  final double size;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: tooltip,
          iconSize: size,
          onPressed: onPressed,
          color: active ? JamColors.accentBright : inactiveColor,
          icon: Icon(icon),
        ),
        if (active)
          Positioned(
            bottom: 2,
            child: IgnorePointer(
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: JamColors.accentBright,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Shuffle, previous, play/pause, next, and repeat.
class TransportControls extends ConsumerWidget {
  const TransportControls({super.key, this.large = false});

  /// The full-screen phone player's spread-out, larger layout.
  final bool large;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shuffle = ref.watch(playbackQueueProvider.select((q) => q.shuffle));
    final repeat = ref.watch(playbackQueueProvider.select((q) => q.repeatMode));
    final casting = ref.watch(castConnectedProvider);
    final player = ref.read(playerControllerProvider);
    final skipColor = large ? Colors.white : JamColors.muted;
    final children = [
      ModeIconButton(
        tooltip: shuffle ? 'Disable shuffle' : 'Enable shuffle',
        icon: Icons.shuffle_rounded,
        active: shuffle,
        size: large ? 26 : 18,
        inactiveColor: skipColor,
        onPressed: casting ? null : player.toggleShuffle,
      ),
      IconButton(
        tooltip: 'Previous',
        iconSize: large ? 42 : 26,
        color: skipColor,
        onPressed: player.previous,
        icon: const Icon(Icons.skip_previous_rounded),
      ),
      PlayPauseButton(size: large ? 68 : 34),
      IconButton(
        tooltip: 'Next',
        iconSize: large ? 42 : 26,
        color: skipColor,
        onPressed: player.next,
        icon: const Icon(Icons.skip_next_rounded),
      ),
      ModeIconButton(
        tooltip: switch (repeat) {
          RepeatMode.off => 'Enable repeat',
          RepeatMode.all => 'Enable repeat one',
          RepeatMode.one => 'Disable repeat',
        },
        icon: repeat == RepeatMode.one
            ? Icons.repeat_one_rounded
            : Icons.repeat_rounded,
        active: repeat != RepeatMode.off,
        size: large ? 26 : 18,
        inactiveColor: skipColor,
        onPressed: casting ? null : player.cycleRepeat,
      ),
    ];
    if (large) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: children,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 6,
      children: children,
    );
  }
}

enum SeekBarLayout {
  /// Times either side of the bar, as in the desktop player bar.
  inline,

  /// Times below the bar, as in the phone player.
  stacked,
}

/// Seek bar for the current track. Only this widget rebuilds on position
/// ticks, not the surrounding player.
class PlaybackSeekBar extends ConsumerWidget {
  const PlaybackSeekBar({super.key, this.layout = SeekBarLayout.inline});

  final SeekBarLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = ref.watch(
      currentTrackProvider.select((track) => track?.duration ?? Duration.zero),
    );
    final position = ref.watch(playbackPositionProvider);
    final player = ref.read(playerControllerProvider);
    const timeStyle = TextStyle(
      fontSize: 12,
      color: JamColors.muted,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    final slider = HoverSlider(
      value: position.inMilliseconds.toDouble(),
      max: duration.inMilliseconds.toDouble(),
      alwaysShowThumb: layout == SeekBarLayout.stacked,
      onChangeEnd: (value) =>
          player.seek(Duration(milliseconds: value.round())),
    );
    return switch (layout) {
      SeekBarLayout.inline => Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              formatDuration(position),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.right,
              style: timeStyle,
            ),
          ),
          Expanded(child: slider),
          SizedBox(
            width: 48,
            child: Text(
              formatDuration(duration),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: timeStyle,
            ),
          ),
        ],
      ),
      SeekBarLayout.stacked => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          slider,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatDuration(position), style: timeStyle),
                Text(formatDuration(duration), style: timeStyle),
              ],
            ),
          ),
        ],
      ),
    };
  }
}

/// Spotify's thin slider: white track that turns green and grows a thumb
/// while hovered or dragged. [onChanged] fires live; [onChangeEnd] commits.
class HoverSlider extends StatefulWidget {
  const HoverSlider({
    required this.value,
    required this.max,
    super.key,
    this.onChanged,
    this.onChangeEnd,
    this.alwaysShowThumb = false,
  });

  final double value;
  final double max;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final bool alwaysShowThumb;

  @override
  State<HoverSlider> createState() => _HoverSliderState();
}

class _HoverSliderState extends State<HoverSlider> {
  var _hovered = false;
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final max = widget.max <= 0 ? 1.0 : widget.max;
    final value = (_dragValue ?? widget.value).clamp(0.0, max);
    final active = _hovered || _dragValue != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 4,
          activeTrackColor: active ? JamColors.accentBright : Colors.white,
          inactiveTrackColor: const Color(0xFF4D4D4D),
          thumbColor: Colors.white,
          overlayColor: Colors.transparent,
          thumbShape: RoundSliderThumbShape(
            enabledThumbRadius: active || widget.alwaysShowThumb ? 6 : 0,
            disabledThumbRadius: 0,
          ),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        ),
        child: Slider(
          value: value,
          max: max,
          onChanged: widget.max <= 0
              ? null
              : (next) {
                  setState(() => _dragValue = next);
                  widget.onChanged?.call(next);
                },
          onChangeEnd: (next) {
            widget.onChangeEnd?.call(next);
            setState(() => _dragValue = null);
          },
        ),
      ),
    );
  }
}

/// The big green play button on an album, playlist, or artist page. It
/// shows pause, and toggles playback, while that page's music is playing.
class ContextPlayButton extends ConsumerWidget {
  const ContextPlayButton({
    required this.isPlayingFrom,
    required this.onPlay,
    super.key,
    this.size = 56,
    this.enabled = true,
  });

  final bool Function(LibraryItem current) isPlayingFrom;
  final VoidCallback onPlay;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentTrackProvider);
    final active = current != null && isPlayingFrom(current);
    final playing = active && ref.watch(playbackPlayingProvider);
    return HoverScale(
      enabled: enabled,
      hoverScale: 1.05,
      child: IconButton.filled(
        tooltip: playing ? 'Pause' : 'Play',
        onPressed: !enabled
            ? null
            : active
            ? () => ref.read(playerControllerProvider).togglePlay()
            : onPlay,
        style: IconButton.styleFrom(
          backgroundColor: JamColors.accent,
          foregroundColor: Colors.black,
          fixedSize: Size.square(size),
          minimumSize: Size.square(size),
          padding: EdgeInsets.zero,
        ),
        iconSize: size * 0.55,
        icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
      ),
    );
  }
}

class VolumeControl extends ConsumerStatefulWidget {
  const VolumeControl({super.key, this.showSlider = true});

  final bool showSlider;

  @override
  ConsumerState<VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends ConsumerState<VolumeControl> {
  var _volumeBeforeMute = 1.0;

  @override
  Widget build(BuildContext context) {
    final volume = ref.watch(playbackVolumeProvider);
    final player = ref.read(playerControllerProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: volume == 0 ? 'Unmute' : 'Mute',
          iconSize: 20,
          onPressed: () {
            if (volume == 0) {
              player.setVolume(_volumeBeforeMute);
            } else {
              _volumeBeforeMute = volume;
              player.setVolume(0);
            }
          },
          icon: Icon(
            volume == 0
                ? Icons.volume_off_rounded
                : volume < 0.5
                ? Icons.volume_down_rounded
                : Icons.volume_up_rounded,
          ),
        ),
        if (widget.showSlider)
          SizedBox(
            width: 100,
            child: HoverSlider(
              value: volume,
              max: 1,
              onChanged: player.setVolume,
            ),
          ),
      ],
    );
  }
}
