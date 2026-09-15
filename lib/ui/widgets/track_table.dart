import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/core/format.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/library_index.dart';
import 'package:jamhorse/state/playback_providers.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';
import 'package:jamhorse/ui/widgets/hoverable.dart';
import 'package:jamhorse/ui/widgets/item_menu.dart';
import 'package:jamhorse/ui/widgets/transport_controls.dart';

const _likeColumn = 40.0;
const _durationColumn = 52.0;
const _menuColumn = 40.0;

/// Column headings for [TrackRow]: #, Title, Album, and duration.
class TrackTableHeader extends StatelessWidget {
  const TrackTableHeader({super.key, this.showAlbum = true});

  final bool showAlbum;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: JamColors.muted,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const SizedBox(
                width: 32,
                child: Text('#', textAlign: TextAlign.center, style: style),
              ),
              const SizedBox(width: 12),
              const Expanded(flex: 5, child: Text('Title', style: style)),
              if (showAlbum)
                const Expanded(flex: 4, child: Text('Album', style: style)),
              const SizedBox(width: _likeColumn),
              const SizedBox(
                width: _durationColumn,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: JamColors.muted,
                  ),
                ),
              ),
              const SizedBox(width: _menuColumn),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

/// Spotify's desktop track row. The playing track turns green with an
/// equalizer in place of its number; hovering reveals play, like, and the
/// "more" menu, and right-click opens the menu too.
class TrackRow extends ConsumerWidget {
  const TrackRow({
    required this.index,
    required this.track,
    required this.onTap,
    super.key,
    this.showAlbum = true,
    this.showArtwork = true,
  });

  final int index;
  final LibraryItem track;
  final VoidCallback onTap;
  final bool showAlbum;
  final bool showArtwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent = ref.watch(
      currentTrackProvider.select((current) => current?.id == track.id),
    );
    final playing = isCurrent && ref.watch(playbackPlayingProvider);
    final downloaded = ref.watch(
      downloadedItemIdsProvider.select((ids) => ids.contains(track.id)),
    );
    final albumName = showAlbum
        ? ref.watch(
            libraryIndexProvider.select((index) => index.albumName(track)),
          )
        : null;
    return Hoverable(
      borderRadius: 4,
      pressedScale: 1,
      onTap: onTap,
      onLongPress: () => showItemMenu(context, ref, track),
      onSecondaryTapUp: (details) =>
          showItemMenu(context, ref, track, position: details.globalPosition),
      builder: (context, hovered) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: hovered
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Center(
                  child: _IndexCell(
                    index: index,
                    hovered: hovered,
                    current: isCurrent,
                    playing: playing,
                    onPressed: isCurrent
                        ? () => ref.read(playerControllerProvider).togglePlay()
                        : onTap,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    if (showArtwork) ...[
                      SizedBox.square(
                        dimension: 40,
                        child: Artwork(
                          item: track,
                          borderRadius: 4,
                          iconSize: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: _TitleAndArtist(
                        track: track,
                        current: isCurrent,
                        downloaded: downloaded,
                        highlight: hovered,
                      ),
                    ),
                  ],
                ),
              ),
              if (showAlbum)
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      albumName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hovered ? Colors.white : JamColors.muted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: _likeColumn,
                child: LikeButton(
                  item: track,
                  size: 18,
                  onlyWhenLiked: !hovered,
                ),
              ),
              SizedBox(
                width: _durationColumn,
                child: Text(
                  track.duration == Duration.zero
                      ? ''
                      : formatDuration(track.duration),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: JamColors.muted, fontSize: 14),
                ),
              ),
              SizedBox(
                width: _menuColumn,
                child: Visibility(
                  visible: hovered,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: ItemMenuButton(item: track, size: 18),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IndexCell extends StatelessWidget {
  const _IndexCell({
    required this.index,
    required this.hovered,
    required this.current,
    required this.playing,
    required this.onPressed,
  });

  final int index;
  final bool hovered;
  final bool current;
  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (hovered) {
      return InkResponse(
        onTap: onPressed,
        radius: 16,
        child: Icon(
          current && playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 20,
          color: Colors.white,
        ),
      );
    }
    if (current && playing) {
      return const Icon(
        Icons.graphic_eq_rounded,
        size: 18,
        color: JamColors.accentBright,
      );
    }
    return Text(
      '$index',
      style: TextStyle(
        color: current ? JamColors.accentBright : JamColors.muted,
        fontSize: 15,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _TitleAndArtist extends StatelessWidget {
  const _TitleAndArtist({
    required this.track,
    required this.current,
    required this.downloaded,
    this.highlight = false,
    this.titleSize = 15,
  });

  final LibraryItem track;
  final bool current;
  final bool downloaded;
  final bool highlight;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          track.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: current ? JamColors.accentBright : Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            if (downloaded)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.download_for_offline_rounded,
                  size: 14,
                  color: JamColors.accentBright,
                ),
              ),
            Flexible(
              child: Text(
                track.artistLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: highlight ? Colors.white : JamColors.muted,
                  fontSize: titleSize - 2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Spotify's phone track row: artwork, title, and artist with the offline
/// badge, plus a trailing control (the "more" menu by default).
class MobileTrackTile extends ConsumerWidget {
  const MobileTrackTile({
    required this.track,
    required this.onTap,
    super.key,
    this.trailing,
    this.showArtwork = true,
  });

  final LibraryItem track;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showArtwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent = ref.watch(
      currentTrackProvider.select((current) => current?.id == track.id),
    );
    final downloaded = ref.watch(
      downloadedItemIdsProvider.select((ids) => ids.contains(track.id)),
    );
    return InkWell(
      onTap: onTap,
      onLongPress: () => showItemMenu(context, ref, track),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          children: [
            if (showArtwork) ...[
              SizedBox.square(
                dimension: 48,
                child: Artwork(item: track, borderRadius: 4, iconSize: 20),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: _TitleAndArtist(
                track: track,
                current: isCurrent,
                downloaded: downloaded,
                titleSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            trailing ?? ItemMenuButton(item: track, size: 22),
          ],
        ),
      ),
    );
  }
}
