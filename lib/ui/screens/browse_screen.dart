import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/library_index.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/layout.dart';
import 'package:jamhorse/ui/widgets/media_row.dart';
import 'package:jamhorse/ui/widgets/track_table.dart';

/// Everything of one type in the library, reached from "Show all" links
/// and the Home chips.
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
      libraryIndexProvider.select(
        (index) => switch (type) {
          LibraryItemType.album => index.albums,
          LibraryItemType.artist => index.artists,
          LibraryItemType.playlist => index.playlists,
          LibraryItemType.genre => index.genres,
          _ => index.tracks,
        },
      ),
    );
    final title = switch (type) {
      LibraryItemType.album => 'Albums',
      LibraryItemType.artist => 'Artists',
      LibraryItemType.playlist => 'Playlists',
      LibraryItemType.genre => 'Genres',
      _ => 'Songs',
    };
    final desktop = isDesktopLayout(context);
    final controller = ref.read(appControllerProvider.notifier);
    return Scaffold(
      backgroundColor: desktop ? Colors.transparent : JamColors.ink,
      appBar: desktop
          ? null
          : AppBar(backgroundColor: JamColors.ink, title: Text(title)),
      body: items.isEmpty
          ? const Center(child: Text('Nothing here yet.'))
          : CustomScrollView(
              slivers: [
                if (desktop)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                  ),
                if (type == LibraryItemType.track) ...[
                  if (desktop)
                    const SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      sliver: SliverToBoxAdapter(child: TrackTableHeader()),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      desktop ? 8 : 0,
                      8,
                      desktop ? 8 : 0,
                      48,
                    ),
                    sliver: SliverList.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final track = items[index];
                        return desktop
                            ? TrackRow(
                                index: index + 1,
                                track: track,
                                onTap: () => controller.play(track),
                              )
                            : MobileTrackTile(
                                track: track,
                                onTap: () => controller.play(track),
                              );
                      },
                    ),
                  ),
                ] else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 48),
                    sliver: SliverArtworkGrid(items: items),
                  ),
              ],
            ),
    );
  }
}
