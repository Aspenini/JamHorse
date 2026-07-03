import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';
import 'package:jamhorse/ui/widgets/track_table.dart';

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final item = state.library.where((entry) => entry.id == itemId).firstOrNull;
    if (item == null) {
      return const Scaffold(
        body: Center(child: Text('This item is no longer in your library.')),
      );
    }
    var children = state.library.where((entry) {
      if (item.type == LibraryItemType.album) return entry.albumId == item.id;
      if (item.type == LibraryItemType.artist) {
        return entry.artistId == item.id &&
            entry.type == LibraryItemType.album;
      }
      return false;
    }).toList(growable: false)
      ..sort(
        (left, right) =>
            (left.indexNumber ?? 9999).compareTo(right.indexNumber ?? 9999),
      );
    // Playlist entries (and album tracks missing from the sync snapshot)
    // come from the server in play order.
    var loadingChildren = false;
    if (children.isEmpty &&
        (item.type == LibraryItemType.playlist ||
            item.type == LibraryItemType.album ||
            item.type == LibraryItemType.genre)) {
      final remote = ref.watch(childrenProvider(item.id));
      loadingChildren = remote.isLoading;
      children = remote.value ?? const [];
    }
    final trackChildren = children
        .where((entry) => entry.type == LibraryItemType.track)
        .toList(growable: false);
    final showAlbumColumn = item.type != LibraryItemType.album;
    final albumNames = ref.watch(albumNamesProvider);
    final downloadedIds = ref.watch(downloadedItemIdsProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 380,
            pinned: true,
            backgroundColor: JamColors.ink,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1B2C55), JamColors.ink],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 54),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: Hero(
                            tag: 'art-${item.serverId}-${item.id}',
                            child: Artwork(item: item, borderRadius: 22),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.subtitle ?? item.type.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (item.productionYear != null)
                          Text(
                            '${item.productionYear}',
                            style: const TextStyle(color: JamColors.muted),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: item.isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                    onPressed: () => ref
                        .read(appControllerProvider.notifier)
                        .toggleFavorite(item),
                    icon: Icon(
                      item.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: item.isFavorite ? JamColors.accent : null,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Download',
                    onPressed: () => ref
                        .read(appControllerProvider.notifier)
                        .download(item),
                    icon: const Icon(Icons.download_rounded),
                  ),
                  const SizedBox(width: 5),
                  IconButton.filled(
                    tooltip: 'Play',
                    onPressed: () =>
                        ref.read(appControllerProvider.notifier).play(item),
                    icon: const Icon(Icons.play_arrow_rounded),
                  ),
                ],
              ),
            ),
          ),
          if (loadingChildren)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (children.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('Nothing inside this item yet.'),
              ),
            )
          else if (trackChildren.length == children.length) ...[
            // A pure track list (album, playlist, genre) gets the
            // Spotify-style table; the album column is redundant on an
            // album's own page.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
              sliver: SliverToBoxAdapter(
                child: TrackTableHeader(showAlbum: showAlbumColumn),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 130),
              sliver: SliverList.builder(
                itemCount: trackChildren.length,
                itemBuilder: (context, index) {
                  final child = trackChildren[index];
                  return TrackRow(
                    index: index + 1,
                    track: child,
                    downloaded: downloadedIds.contains(child.id),
                    showAlbum: showAlbumColumn,
                    albumName: child.albumId == null
                        ? null
                        : albumNames[child.albumId],
                    onTap: () => ref
                        .read(appControllerProvider.notifier)
                        .playQueue(trackChildren, startWith: child),
                  );
                },
              ),
            ),
          ] else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 130),
              sliver: SliverList.separated(
                itemCount: children.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final child = children[index];
                  return ListTile(
                    leading: SizedBox.square(
                      dimension: 50,
                      child: Artwork(
                        item: child,
                        borderRadius: 9,
                        iconSize: 24,
                      ),
                    ),
                    title: Text(
                      child.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      child.subtitle ?? child.type.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: child.duration == Duration.zero
                        ? null
                        : Text(_duration(child.duration)),
                    onTap: () => child.type == LibraryItemType.track
                        ? ref
                              .read(appControllerProvider.notifier)
                              .playQueue(trackChildren, startWith: child)
                        : context.push('/item/${child.id}'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _duration(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
