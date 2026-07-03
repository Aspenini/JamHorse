import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/track_table.dart';

class LikedSongsScreen extends ConsumerWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(
      appControllerProvider.select(
        (state) => state.library
            .where(
              (item) =>
                  item.type == LibraryItemType.track && item.isFavorite,
            )
            .toList(growable: false),
      ),
    );
    final controller = ref.read(appControllerProvider.notifier);
    final albumNames = ref.watch(albumNamesProvider);
    final downloadedIds = ref.watch(downloadedItemIdsProvider);
    final total = liked.fold(Duration.zero, (sum, item) => sum + item.duration);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            backgroundColor: JamColors.ink,
            flexibleSpace: FlexibleSpaceBar(
              background: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF24438C), Color(0xFF13223F), JamColors.ink],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                JamColors.accentBright,
                                JamColors.accent,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 52,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Liked Songs',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${liked.length} songs · '
                                '${total.inHours} hr ${total.inMinutes.remainder(60)} min',
                                style: const TextStyle(
                                  color: JamColors.muted,
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
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: liked.isEmpty
                        ? null
                        : () => controller.playQueue(liked),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: liked.isEmpty
                        ? null
                        : () => controller.playQueue(liked, shuffle: true),
                    icon: const Icon(Icons.shuffle_rounded),
                    label: const Text('Shuffle'),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Download all',
                    onPressed: liked.isEmpty
                        ? null
                        : () {
                            controller.downloadAll(liked);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Downloading ${liked.length} songs',
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.download_rounded),
                  ),
                ],
              ),
            ),
          ),
          if (liked.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Text(
                    'Tap the heart on any song to add it here.\n'
                    'Likes sync with Jellyfin favorites.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: JamColors.muted),
                  ),
                ),
              ),
            )
          else ...[
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(4, 10, 4, 0),
              sliver: SliverToBoxAdapter(child: TrackTableHeader()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 40),
              sliver: SliverList.builder(
                itemCount: liked.length,
                itemBuilder: (context, index) {
                  final item = liked[index];
                  return TrackRow(
                    index: index + 1,
                    track: item,
                    downloaded: downloadedIds.contains(item.id),
                    albumName: item.albumId == null
                        ? null
                        : albumNames[item.albumId],
                    onTap: () =>
                        controller.playQueue(liked, startWith: item),
                    action: IconButton(
                      tooltip: 'Remove from Liked Songs',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => controller.toggleFavorite(item),
                      icon: const Icon(
                        Icons.favorite_rounded,
                        color: JamColors.accentBright,
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
