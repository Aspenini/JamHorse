import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';

/// Full grid of one library type, reached from a Home section's
/// "Show all" link.
class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({required this.typeName, super.key});

  final String typeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = LibraryItemType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => LibraryItemType.album,
    );
    final items = ref.watch(
      appControllerProvider.select(
        (state) => state.library
            .where((item) => item.type == type)
            .toList(growable: false),
      ),
    );
    final title = switch (type) {
      LibraryItemType.album => 'Albums',
      LibraryItemType.artist => 'Artists',
      LibraryItemType.playlist => 'Playlists',
      LibraryItemType.genre => 'Genres',
      _ => 'Songs',
    };
    return Scaffold(
      body: items.isEmpty
          ? const Center(child: Text('Nothing here yet.'))
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.crossAxisExtent;
                      final extent = width >= 1200
                          ? 210.0
                          : width >= 700
                          ? 190.0
                          : 160.0;
                      return SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: extent,
                          mainAxisExtent: extent + 68,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ArtworkCard(
                            item: item,
                            width: extent,
                            onPlay: () async {
                              final controller = ref.read(
                                appControllerProvider.notifier,
                              );
                              if (item.type == LibraryItemType.track) {
                                await controller.play(item);
                                return;
                              }
                              final children = await ref.read(
                                childrenProvider(item.id).future,
                              );
                              final tracks = children
                                  .where(
                                    (child) =>
                                        child.type == LibraryItemType.track,
                                  )
                                  .toList(growable: false);
                              if (tracks.isNotEmpty) {
                                await controller.playQueue(tracks);
                              }
                            },
                            onTap: () => item.type == LibraryItemType.track
                                ? ref
                                      .read(appControllerProvider.notifier)
                                      .play(item)
                                : context.push('/item/${item.id}'),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
