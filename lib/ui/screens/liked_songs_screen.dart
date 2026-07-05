import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/interaction.dart';
import 'package:jamhorse/ui/widgets/track_table.dart';
import 'package:jamhorse/ui/widgets/user_avatar.dart';

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
    // Matches the shell's desktop/mobile breakpoint so the screen never
    // shows desktop chrome inside the phone shell.
    final desktop = MediaQuery.sizeOf(context).width >= 920;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          if (!desktop)
            SliverAppBar(
              pinned: true,
              expandedHeight: 200,
              backgroundColor: const Color(0xFF38286E),
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
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
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Liked Songs',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${liked.length} songs',
                              style: const TextStyle(
                                color: Color(0xFFD5CCF1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            SliverAppBar(
              pinned: true,
              toolbarHeight: 0,
              expandedHeight: 350,
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
                    padding: const EdgeInsets.fromLTRB(28, 70, 28, 28),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 220,
                          height: 220,
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
                                  const SizedBox.square(
                                    dimension: 24,
                                    child: UserAvatar(size: 24),
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
            padding: desktop
                ? const EdgeInsets.fromLTRB(28, 26, 28, 12)
                : const EdgeInsets.fromLTRB(16, 12, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  if (!desktop) ...[
                    // Spotify's phone layout: a small playlist tile and
                    // download on the left, shuffle and play on the right.
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)],
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (desktop) ...[
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
                  ],
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
                    icon: Icon(
                      Icons.download_for_offline_outlined,
                      size: desktop ? 32 : 28,
                    ),
                  ),
                  const Spacer(),
                  if (desktop) ...[
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
                  ] else ...[
                    IconButton(
                      tooltip: 'Shuffle',
                      onPressed: liked.isEmpty
                          ? null
                          : () => controller.playQueue(liked, shuffle: true),
                      icon: const Icon(
                        Icons.shuffle_rounded,
                        color: JamColors.accent,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filled(
                      tooltip: 'Play',
                      onPressed: liked.isEmpty
                          ? null
                          : () => controller.playQueue(liked),
                      style: IconButton.styleFrom(
                        backgroundColor: JamColors.accent,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.square(56),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 32),
                    ),
                  ],
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
          else if (!desktop)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 6, 0, 40),
              sliver: SliverList.builder(
                itemCount: liked.length,
                itemBuilder: (context, index) {
                  final item = liked[index];
                  return MobileTrackTile(
                    track: item,
                    downloaded: downloadedIds.contains(item.id),
                    onTap: () => controller.playQueue(liked, startWith: item),
                    trailing: IconButton(
                      tooltip: 'Remove from Liked Songs',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => controller.toggleFavorite(item),
                      icon: const Icon(
                        Icons.favorite_rounded,
                        color: JamColors.accentBright,
                        size: 20,
                      ),
                    ),
                  );
                },
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
