import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/app/theme.dart';
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
      appBar: AppBar(
        title: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: JamColors.ink,
      ),
      body: items.isEmpty
          ? const Center(child: Text('Nothing here yet.'))
          : LayoutBuilder(
              builder: (context, constraints) {
                final extent = constraints.maxWidth >= 1200
                    ? 190.0
                    : constraints.maxWidth >= 700
                    ? 170.0
                    : 145.0;
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: extent,
                    mainAxisExtent: extent + 58,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 18,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ArtworkCard(
                      item: item,
                      width: extent,
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
    );
  }
}
