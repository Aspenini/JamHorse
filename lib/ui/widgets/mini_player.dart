import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/state/playback_providers.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';
import 'package:jamhorse/ui/widgets/artwork_color.dart';
import 'package:jamhorse/ui/widgets/transport_controls.dart';

/// Spotify's phone mini player: a card tinted by the artwork, floating above
/// the tab bar, with a hairline progress bar along its bottom edge.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    if (track == null) return const SizedBox.shrink();
    final tint = ref.artworkColor(track, fallback: const Color(0xFF35333F));
    return Semantics(
      button: true,
      label: 'Now playing ${track.name}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            type: MaterialType.transparency,
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
                          dimension: 40,
                          child: Artwork(
                            item: track,
                            borderRadius: 4,
                            iconSize: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                track.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                track.artistLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        LikeButton(item: track, size: 22),
                        const _PlayPauseIcon(),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 7),
                    child: _MiniProgress(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayPauseIcon extends ConsumerWidget {
  const _PlayPauseIcon();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(playbackPlayingProvider);
    return IconButton(
      tooltip: playing ? 'Pause' : 'Play',
      iconSize: 30,
      color: Colors.white,
      onPressed: () => ref.read(playerControllerProvider).togglePlay(),
      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
    );
  }
}

class _MiniProgress extends ConsumerWidget {
  const _MiniProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = ref.watch(
      currentTrackProvider.select((track) => track?.duration ?? Duration.zero),
    );
    final position = ref.watch(playbackPositionProvider);
    final progress = duration <= Duration.zero
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 2,
        color: Colors.white,
        backgroundColor: Colors.white24,
      ),
    );
  }
}
