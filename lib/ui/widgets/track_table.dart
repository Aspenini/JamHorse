import 'package:flutter/material.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';

/// Spotify-style track listing: index, artwork + title + artist, album,
/// and duration columns, with a header row.
class TrackTableHeader extends StatelessWidget {
  const TrackTableHeader({super.key, this.showAlbum = true});

  final bool showAlbum;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: JamColors.muted,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 28, child: Text('#', style: style)),
              const SizedBox(width: 12),
              const Expanded(flex: 5, child: Text('TITLE', style: style)),
              if (showAlbum)
                const Expanded(flex: 4, child: Text('ALBUM', style: style)),
              const SizedBox(
                width: 50,
                child: Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: JamColors.muted,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class TrackRow extends StatelessWidget {
  const TrackRow({
    required this.index,
    required this.track,
    required this.onTap,
    super.key,
    this.albumName,
    this.showAlbum = true,
    this.action,
  });

  final int index;
  final LibraryItem track;
  final String? albumName;
  final bool showAlbum;
  final VoidCallback onTap;

  /// Optional small control (e.g. an un-like heart) shown before the
  /// duration.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '$index',
                style: const TextStyle(color: JamColors.muted),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 42,
                    child: Artwork(
                      item: track,
                      borderRadius: 6,
                      iconSize: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          track.subtitle ?? 'Unknown artist',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: JamColors.muted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
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
                    style: const TextStyle(
                      color: JamColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: action == null ? 50 : 92,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ?action,
                  Text(
                    _time(track.duration),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: JamColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _time(Duration value) {
    if (value == Duration.zero) return '';
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
