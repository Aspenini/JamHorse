import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/library_index.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/state/ui_state.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';
import 'package:jamhorse/ui/widgets/hoverable.dart';
import 'package:jamhorse/ui/widgets/item_menu.dart';

String _filterLabel(LibraryFilter filter) => switch (filter) {
  LibraryFilter.playlists => 'Playlists',
  LibraryFilter.albums => 'Albums',
  LibraryFilter.artists => 'Artists',
  LibraryFilter.downloaded => 'Downloaded',
};

String _sortLabel(LibrarySort sort) => switch (sort) {
  LibrarySort.recentlyAdded => 'Recently added',
  LibrarySort.alphabetical => 'Alphabetical',
  LibrarySort.creator => 'Creator',
};

String libraryEntrySubtitle(LibraryItem item) => switch (item.type) {
  LibraryItemType.playlist => 'Playlist',
  LibraryItemType.artist => 'Artist',
  LibraryItemType.album =>
    item.subtitle?.isNotEmpty ?? false ? 'Album • ${item.subtitle}' : 'Album',
  _ => item.subtitle ?? '',
};

/// Filter chips, in-library search, sort order, and grid/list toggle.
class LibraryToolbar extends ConsumerStatefulWidget {
  const LibraryToolbar({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final EdgeInsets padding;

  @override
  ConsumerState<LibraryToolbar> createState() => _LibraryToolbarState();
}

class _LibraryToolbarState extends ConsumerState<LibraryToolbar> {
  final _searchController = TextEditingController();
  var _searching = false;

  @override
  void initState() {
    super.initState();
    final query = ref.read(libraryViewProvider).query;
    _searchController.text = query;
    _searching = query.isNotEmpty;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _closeSearch() {
    _searchController.clear();
    ref.read(libraryViewProvider.notifier).setQuery('');
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(libraryViewProvider);
    final controller = ref.read(libraryViewProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            padding: widget.padding.copyWith(top: 4, bottom: 4),
            scrollDirection: Axis.horizontal,
            children: [
              if (view.filter case final filter?) ...[
                IconButton.filledTonal(
                  tooltip: 'Clear filter',
                  iconSize: 18,
                  style: IconButton.styleFrom(
                    backgroundColor: JamColors.soft,
                    minimumSize: const Size.square(34),
                  ),
                  onPressed: () => controller.toggleFilter(filter),
                  icon: const Icon(Icons.close_rounded),
                ),
                const SizedBox(width: 8),
              ],
              for (final filter in LibraryFilter.values)
                if (view.filter == null || view.filter == filter)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_filterLabel(filter)),
                      selected: view.filter == filter,
                      showCheckmark: false,
                      onSelected: (_) => controller.toggleFilter(filter),
                    ),
                  ),
            ],
          ),
        ),
        Padding(
          padding: widget.padding.copyWith(top: 2, bottom: 2),
          child: Row(
            children: [
              if (_searching)
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 14),
                    onChanged: controller.setQuery,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search in Your Library',
                      hintStyle: const TextStyle(fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      suffixIcon: IconButton(
                        tooltip: 'Close search',
                        iconSize: 18,
                        onPressed: _closeSearch,
                        icon: const Icon(Icons.close_rounded),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                )
              else ...[
                IconButton(
                  tooltip: 'Search in Your Library',
                  iconSize: 20,
                  onPressed: () => setState(() => _searching = true),
                  icon: const Icon(Icons.search_rounded),
                ),
                const Spacer(),
              ],
              PopupMenuButton<LibrarySort>(
                tooltip: 'Sort by',
                initialValue: view.sort,
                onSelected: controller.setSort,
                itemBuilder: (context) => [
                  for (final sort in LibrarySort.values)
                    CheckedPopupMenuItem(
                      value: sort,
                      checked: sort == view.sort,
                      child: Text(_sortLabel(sort)),
                    ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Text(
                    _sortLabel(view.sort),
                    style: const TextStyle(
                      color: JamColors.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: view.grid ? 'Show as list' : 'Show as grid',
                iconSize: 18,
                onPressed: controller.toggleGrid,
                icon: Icon(
                  view.grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Liked Songs and Downloads pinned first, then the filtered and sorted
/// library, as a grid or a compact list.
class LibraryEntriesView extends ConsumerWidget {
  const LibraryEntriesView({
    required this.onNavigate,
    super.key,
    this.selectedPath,
    this.padding = const EdgeInsets.fromLTRB(12, 4, 12, 24),
  });

  final ValueChanged<String> onNavigate;
  final String? selectedPath;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(libraryViewProvider);
    final entries = ref.watch(libraryEntriesProvider);
    final likedCount = ref.watch(
      libraryIndexProvider.select((index) => index.likedTracks.length),
    );
    final controller = ref.read(appControllerProvider.notifier);
    final showPinned =
        view.query.trim().isEmpty &&
        (view.filter == null || view.filter == LibraryFilter.playlists);
    final grid = view.grid;
    final pinned = <Widget>[
      if (showPinned) ...[
        LibraryEntryTile(
          title: 'Liked Songs',
          subtitle: 'Playlist • $likedCount songs',
          grid: grid,
          selected: selectedPath == '/liked',
          artwork: LikedSongsArt(iconSize: grid ? 40 : 20),
          onTap: () => onNavigate('/liked'),
          onPlay: likedCount == 0
              ? null
              : () => controller.playQueue(
                  ref.read(libraryIndexProvider).likedTracks,
                ),
        ),
        LibraryEntryTile(
          title: 'Downloads',
          subtitle: 'Saved on this device',
          grid: grid,
          selected: selectedPath == '/downloads',
          artwork: DownloadsArt(iconSize: grid ? 40 : 20),
          onTap: () => onNavigate('/downloads'),
          onPlay: () {
            final ids = ref.read(downloadedItemIdsProvider);
            controller.playQueue([
              for (final track in ref.read(libraryIndexProvider).tracks)
                if (ids.contains(track.id)) track,
            ]);
          },
        ),
      ],
    ];
    if (pinned.isEmpty && entries.isEmpty) {
      return const Center(
        child: Text(
          'Nothing here matches.',
          style: TextStyle(color: JamColors.muted),
        ),
      );
    }
    Widget tileAt(int index) {
      if (index < pinned.length) return pinned[index];
      final item = entries[index - pinned.length];
      return LibraryEntryTile(
        item: item,
        title: item.name,
        subtitle: libraryEntrySubtitle(item),
        grid: grid,
        circular: item.type == LibraryItemType.artist,
        selected: selectedPath == '/item/${item.id}',
        artwork: Artwork(item: item, borderRadius: 0, iconSize: grid ? 32 : 20),
        onTap: () => onNavigate('/item/${item.id}'),
        onPlay: () => controller.play(item),
      );
    }

    final count = pinned.length + entries.length;
    if (!grid) {
      return ListView.builder(
        padding: padding,
        itemCount: count,
        itemBuilder: (context, index) => tileAt(index),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 150).floor().clamp(1, 8);
        return GridView.builder(
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.74,
          ),
          itemCount: count,
          itemBuilder: (context, index) => tileAt(index),
        );
      },
    );
  }
}

class LibraryEntryTile extends ConsumerWidget {
  const LibraryEntryTile({
    required this.title,
    required this.subtitle,
    required this.artwork,
    required this.onTap,
    super.key,
    this.item,
    this.onPlay,
    this.grid = true,
    this.selected = false,
    this.circular = false,
  });

  final String title;
  final String subtitle;
  final Widget artwork;
  final VoidCallback onTap;
  final LibraryItem? item;
  final VoidCallback? onPlay;
  final bool grid;
  final bool selected;
  final bool circular;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = item;
    final radius = BorderRadius.circular(circular ? 999 : (grid ? 6 : 4));
    final titleStyle = TextStyle(
      color: selected ? JamColors.accentBright : Colors.white,
      fontWeight: grid ? FontWeight.w700 : FontWeight.w500,
      fontSize: grid ? 14 : 15,
    );
    const subtitleStyle = TextStyle(color: JamColors.muted, fontSize: 13);
    return Hoverable(
      semanticLabel: '$title, $subtitle',
      selected: selected,
      borderRadius: 6,
      hoverScale: grid ? 1.015 : 1,
      onTap: onTap,
      onLongPress: entry == null
          ? null
          : () => showItemMenu(context, ref, entry),
      onSecondaryTapUp: entry == null
          ? null
          : (details) => showItemMenu(
              context,
              ref,
              entry,
              position: details.globalPosition,
            ),
      builder: (context, hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: grid
            ? const EdgeInsets.all(8)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.1)
              : hovered
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: grid
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(borderRadius: radius, child: artwork),
                          if (onPlay != null)
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: PlayOverlayButton(
                                visible: hovered,
                                size: 42,
                                onPressed: onPlay!,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: subtitleStyle,
                  ),
                ],
              )
            : Row(
                children: [
                  SizedBox.square(
                    dimension: 48,
                    child: ClipRRect(borderRadius: radius, child: artwork),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: subtitleStyle,
                        ),
                      ],
                    ),
                  ),
                  if (onPlay != null)
                    Visibility(
                      visible: hovered,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: IconButton(
                        tooltip: 'Play $title',
                        onPressed: onPlay,
                        icon: const Icon(Icons.play_arrow_rounded),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
