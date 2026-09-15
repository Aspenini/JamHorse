import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/playback_providers.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/state/ui_state.dart';
import 'package:jamhorse/ui/navigation.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';
import 'package:jamhorse/ui/widgets/hoverable.dart';
import 'package:jamhorse/ui/widgets/interaction.dart';
import 'package:jamhorse/ui/widgets/output_picker.dart';
import 'package:jamhorse/ui/widgets/transport_controls.dart';

/// Spotify's desktop playback bar: track info, transport and seek, and the
/// panel, device, and volume controls.
class PlayerBar extends ConsumerWidget {
  const PlayerBar({super.key});

  static const height = 92.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    return SizedBox(
      height: height,
      child: ColoredBox(
        color: JamColors.ink,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: track == null
              ? const Center(
                  child: Text(
                    'Choose something to play',
                    style: TextStyle(color: JamColors.muted),
                  ),
                )
              : Row(
                  children: [
                    Expanded(flex: 3, child: _TrackInfo(track: track)),
                    const Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [TransportControls(), PlaybackSeekBar()],
                      ),
                    ),
                    const Expanded(flex: 3, child: _BarActions()),
                  ],
                ),
        ),
      ),
    );
  }
}

class _TrackInfo extends ConsumerWidget {
  const _TrackInfo({required this.track});

  final LibraryItem track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EntranceMotion(
      watchKey: track.id,
      child: Row(
        children: [
          Tooltip(
            message: 'Now playing view',
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => ref
                  .read(rightPanelProvider.notifier)
                  .toggle(RightPanelView.nowPlaying),
              child: SizedBox.square(
                dimension: 56,
                child: Artwork(item: track, borderRadius: 4, iconSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinkText(
                  track.name,
                  onTap: () => openItem(context, track),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                LinkText(
                  track.artistLine,
                  onTap: track.artistId == null
                      ? null
                      : () => openArtist(context, track),
                  style: const TextStyle(color: JamColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          LikeButton(item: track, size: 18),
        ],
      ),
    );
  }
}

class _BarActions extends ConsumerWidget {
  const _BarActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panel = ref.watch(rightPanelProvider);
    final panels = ref.read(rightPanelProvider.notifier);
    final bridge = ref.watch(platformMediaBridgeProvider);
    final capabilities =
        ref.watch(platformCapabilitiesProvider).value ?? bridge.capabilities;
    final casting = ref.watch(castConnectedProvider);
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ModeIconButton(
            tooltip: 'Now playing view',
            icon: Icons.slideshow_outlined,
            active: panel == RightPanelView.nowPlaying,
            onPressed: () => panels.toggle(RightPanelView.nowPlaying),
          ),
          ModeIconButton(
            tooltip: 'Lyrics',
            icon: Icons.lyrics_outlined,
            active: panel == RightPanelView.lyrics,
            onPressed: () => panels.toggle(RightPanelView.lyrics),
          ),
          ModeIconButton(
            tooltip: 'Queue',
            icon: Icons.queue_music_rounded,
            active: panel == RightPanelView.queue,
            onPressed: () => panels.toggle(RightPanelView.queue),
          ),
          if (capabilities.googleCast || capabilities.airPlay)
            ModeIconButton(
              tooltip: casting ? 'Casting' : 'Connect to a device',
              icon: casting
                  ? Icons.cast_connected_rounded
                  : Icons.speaker_group_outlined,
              active: casting,
              onPressed: () => showOutputPicker(context, ref),
            ),
          VolumeControl(showSlider: constraints.maxWidth >= 320),
        ],
      ),
    );
  }
}
