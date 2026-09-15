import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/playback_providers.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';
import 'package:jamhorse/ui/widgets/item_menu.dart';

/// "Now playing" plus everything after it in play order (shuffle-aware).
/// Up-next tracks can be dragged into a new order while not shuffled.
class QueuePanel extends ConsumerWidget {
  const QueuePanel({super.key, this.padding = const EdgeInsets.all(12)});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(playbackQueueProvider);
    final casting = ref.watch(castConnectedProvider);
    final current = queue.current;
    if (current == null) {
      return const Center(
        child: Text(
          'Add songs to your queue to see them here.',
          style: TextStyle(color: JamColors.muted),
        ),
      );
    }
    final upNext = queue.upNextIndices;
    final player = ref.read(playerControllerProvider);
    final reorderable = !queue.shuffle && !casting;
    Widget tile(int index) => _QueueTile(
      item: queue.items[index],
      current: index == queue.currentIndex,
      onTap: casting ? null : () => player.skipToIndex(index),
      onRemove: casting || queue.items.length < 2
          ? null
          : () => player.removeQueueItemAt(index),
    );
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: padding.copyWith(bottom: 0),
          sliver: SliverList.list(
            children: [
              const _Heading('Now playing'),
              tile(queue.currentIndex),
              const SizedBox(height: 16),
              if (upNext.isNotEmpty)
                _Heading(queue.shuffle ? 'Next up (shuffled)' : 'Next up'),
            ],
          ),
        ),
        SliverPadding(
          padding: padding.copyWith(top: 0),
          sliver: reorderable
              ? SliverReorderableList(
                  itemCount: upNext.length,
                  onReorderItem: (from, to) =>
                      player.moveQueueItem(upNext[from], upNext[to]),
                  itemBuilder: (context, position) {
                    final index = upNext[position];
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey('${queue.items[index].id}-$index'),
                      index: position,
                      child: Material(
                        type: MaterialType.transparency,
                        child: tile(index),
                      ),
                    );
                  },
                )
              : SliverList.builder(
                  itemCount: upNext.length,
                  itemBuilder: (context, position) => tile(upNext[position]),
                ),
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _QueueTile extends ConsumerWidget {
  const _QueueTile({
    required this.item,
    required this.current,
    required this.onTap,
    required this.onRemove,
  });

  final LibraryItem item;
  final bool current;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      hoverColor: Colors.white10,
      leading: SizedBox.square(
        dimension: 44,
        child: Artwork(item: item, borderRadius: 4, iconSize: 18),
      ),
      title: Text(
        item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: current ? JamColors.accentBright : Colors.white,
        ),
      ),
      subtitle: Text(
        item.artistLine,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: JamColors.muted),
      ),
      onTap: onTap,
      onLongPress: () => showItemMenu(context, ref, item),
      trailing: current || onRemove == null
          ? ItemMenuButton(item: item, size: 18)
          : IconButton(
              tooltip: 'Remove from queue',
              iconSize: 18,
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
    );
  }
}

/// Lyrics for [item]. Synced lyrics highlight and follow the current line,
/// and tapping a timed line seeks to it.
class LyricsPanel extends ConsumerStatefulWidget {
  const LyricsPanel({
    required this.item,
    super.key,
    this.padding = const EdgeInsets.all(24),
  });

  final LibraryItem item;
  final EdgeInsets padding;

  @override
  ConsumerState<LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends ConsumerState<LyricsPanel> {
  final _lineKeys = <GlobalKey>[];
  int _followedLine = -1;

  static int _activeLine(List<LyricsLine> lines, Duration position) {
    var active = -1;
    for (var index = 0; index < lines.length; index++) {
      final start = lines[index].start;
      if (start == null || start > position) break;
      active = index;
    }
    return active;
  }

  void _follow(int line) {
    if (line == _followedLine || line < 0 || line >= _lineKeys.length) return;
    _followedLine = line;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lineContext = _lineKeys[line].currentContext;
      if (lineContext == null || !lineContext.mounted) return;
      Scrollable.ensureVisible(
        lineContext,
        alignment: 0.35,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = ref.watch(lyricsProvider(widget.item.id));
    return switch (lyrics) {
      AsyncValue(isLoading: true, value: null) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      AsyncValue(value: final lines?) when lines.isNotEmpty => _buildLines(
        lines,
      ),
      _ => const Center(
        child: Text(
          'No lyrics for this song.',
          style: TextStyle(color: JamColors.muted),
        ),
      ),
    };
  }

  Widget _buildLines(List<LyricsLine> lines) {
    final synced = lines.any((line) => line.start != null);
    final active = synced
        ? ref.watch(
            playbackPositionProvider.select(
              (position) => _activeLine(lines, position),
            ),
          )
        : -1;
    while (_lineKeys.length < lines.length) {
      _lineKeys.add(GlobalKey());
    }
    if (synced) _follow(active);
    final style = Theme.of(context).textTheme.headlineMedium;
    return SingleChildScrollView(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < lines.length; index++)
            Padding(
              key: _lineKeys[index],
              padding: const EdgeInsets.only(bottom: 14),
              child: MouseRegion(
                cursor: lines[index].start == null
                    ? MouseCursor.defer
                    : SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: lines[index].start == null
                      ? null
                      : () => ref
                            .read(playerControllerProvider)
                            .seek(lines[index].start!),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: (style ?? const TextStyle()).copyWith(
                      color: !synced || index == active
                          ? Colors.white
                          : index < active
                          ? Colors.white54
                          : Colors.white30,
                    ),
                    child: Text(lines[index].text),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
