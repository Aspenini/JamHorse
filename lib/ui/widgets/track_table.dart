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
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          child: Row(
            children: [
              const SizedBox(width: 28, child: Text('#', style: style)),
              const SizedBox(width: 12),
              const Expanded(flex: 5, child: Text('Title', style: style)),
              if (showAlbum)
                const Expanded(flex: 4, child: Text('Album', style: style)),
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

class TrackRow extends StatefulWidget {
  const TrackRow({
    required this.index,
    required this.track,
    required this.onTap,
    super.key,
    this.albumName,
    this.showAlbum = true,
    this.downloaded = false,
    this.action,
  });

  final int index;
  final LibraryItem track;
  final String? albumName;
  final bool showAlbum;

  /// Shows the offline badge: this track plays from its local file.
  final bool downloaded;
  final VoidCallback onTap;

  /// Optional small control (e.g. an un-like heart) shown before the
  /// duration.
  final Widget? action;

  @override
  State<TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<TrackRow> {
  var _hovered = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: AnimatedScale(
        scale: _pressed ? 0.995 : 1,
        duration: const Duration(milliseconds: 90),
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          hoverColor: Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.075)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 7),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 120),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _hovered
                        ? const Icon(
                            Icons.play_arrow_rounded,
                            key: ValueKey('play'),
                            size: 20,
                            color: Colors.white,
                          )
                        : Text(
                            '${widget.index}',
                            key: const ValueKey('index'),
                            style: const TextStyle(color: JamColors.muted),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      AnimatedScale(
                        scale: _hovered ? 1.035 : 1,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: SizedBox.square(
                          dimension: 42,
                          child: Artwork(
                            item: widget.track,
                            borderRadius: 5,
                            iconSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 120),
                              style: TextStyle(
                                color: _hovered
                                    ? Colors.white
                                    : const Color(0xFFF0F0F0),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              child: Text(
                                widget.track.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                if (widget.downloaded)
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
                                    widget.track.subtitle ?? 'Unknown artist',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: JamColors.muted,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.showAlbum)
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        widget.albumName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _hovered
                              ? const Color(0xFFE3E3E3)
                              : JamColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                SizedBox(
                  width: widget.action == null ? 50 : 92,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.action case final action?)
                        AnimatedOpacity(
                          opacity: _hovered ? 1 : 0.88,
                          duration: const Duration(milliseconds: 120),
                          child: action,
                        ),
                      Text(
                        _time(widget.track.duration),
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
