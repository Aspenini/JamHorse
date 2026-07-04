import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/interaction.dart';
import 'package:jamhorse/ui/widgets/track_table.dart';

class LikedSongsScreen extends ConsumerWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(
      appControllerProvider.select(
        (state) => state.library
            .where(
              (item) => item.type == LibraryItemType.track && item.isFavorite,
            )
            .toList(growable: false),
      ),
    );
    final controller = ref.read(appControllerProvider.notifier);
    final albumNames = ref.watch(albumNamesProvider);
    final downloadedIds = ref.watch(downloadedItemIdsProvider);
    final username = ref.watch(
      appControllerProvider.select(
        (state) => state.session?.profile.username ?? 'You',
      ),
    );
    final total = liked.fold(Duration.zero, (sum, item) => sum + item.duration);
    final desktop = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 0,
            expandedHeight: desktop ? 350 : 260,
            backgroundColor: const Color(0xFF291E4B),
            flexibleSpace: FlexibleSpaceBar(
              background: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF5B3BB2),
                      Color(0xFF38286E),
                      Color(0xFF291E4B),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    desktop ? 28 : 20,
                    desktop ? 70 : 36,
                    desktop ? 28 : 20,
                    28,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: desktop ? 220 : 150,
                        height: desktop ? 220 : 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 28,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 82,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Playlist',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Liked Songs',
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: JamColors.soft,
                                  child: Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '$username · ${liked.length} songs, '
                                    '${total.inHours} hr '
                                    '${total.inMinutes.remainder(60)} min',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFE0E0E0),
                                      fontWeight: FontWeight.w600,
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
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  HoverScale(
                    enabled: liked.isNotEmpty,
                    hoverScale: 1.075,
                    child: IconButton.filled(
                      tooltip: 'Play',
                      onPressed: liked.isEmpty
                          ? null
                          : () => controller.playQueue(liked),
                      style: IconButton.styleFrom(
                        backgroundColor: JamColors.accent,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.square(64),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 38),
                    ),
                  ),
                  const SizedBox(width: 18),
                  HoverScale(
                    enabled: liked.isNotEmpty,
                    child: IconButton(
                      tooltip: 'Shuffle',
                      onPressed: liked.isEmpty
                          ? null
                          : () => controller.playQueue(liked, shuffle: true),
                      icon: const Icon(
                        Icons.shuffle_rounded,
                        color: JamColors.accent,
                        size: 34,
                      ),
                    ),
                  ),
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
                    icon: const Icon(
                      Icons.download_for_offline_outlined,
                      size: 32,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.search_rounded, color: JamColors.muted),
                  const SizedBox(width: 22),
                  const Text(
                    'Recently added',
                    style: TextStyle(
                      color: JamColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.list_rounded, color: JamColors.muted),
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
                    albumName:
                        item.albumName ??
                        (item.albumId == null
                            ? null
                            : albumNames[item.albumId]),
                    onTap: () => controller.playQueue(liked, startWith: item),
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
