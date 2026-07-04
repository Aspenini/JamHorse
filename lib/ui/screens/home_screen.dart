import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final query = ref.watch(searchQueryProvider).trim();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: JamColors.accent,
        onRefresh: () async {
          await ref.read(appControllerProvider.notifier).synchronize();
          ref.invalidate(recentlyAddedProvider);
          ref.invalidate(genreAlbumsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2A2A2A), JamColors.elevated],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              query.isEmpty
                                  ? _greeting()
                                  : 'Search results for “$query”',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                          ),
                          if (state.syncing)
                            const Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          IconButton(
                            tooltip: 'Shuffle everything',
                            onPressed: ref
                                .read(appControllerProvider.notifier)
                                .shuffleAll,
                            icon: const Icon(Icons.shuffle_rounded),
                          ),
                          IconButton(
                            tooltip: 'Refresh library',
                            onPressed: state.syncing
                                ? null
                                : ref
                                      .read(appControllerProvider.notifier)
                                      .synchronize,
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                      if (query.isEmpty) ...[
                        const SizedBox(height: 22),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('All'),
                              selected: true,
                              showCheckmark: false,
                              onSelected: (_) {},
                            ),
                            ActionChip(
                              label: const Text('Music'),
                              onPressed: () => context.go('/browse/track'),
                            ),
                            ActionChip(
                              label: const Text('Playlists'),
                              onPressed: () => context.go('/collection'),
                            ),
                            ActionChip(
                              label: const Text('Albums'),
                              onPressed: () => context.go('/browse/album'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (query.isNotEmpty)
              _SearchResults(results: state.searchResults)
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                sliver: SliverList.list(
                  children: [
                    if (state.error != null)
                      _OfflineBanner(
                        message: state.error!,
                        onDismiss: ref
                            .read(appControllerProvider.notifier)
                            .clearError,
                      ),
                    if (state.library.isEmpty && !state.syncing)
                      const _EmptyLibrary()
                    else ...[
                      const _RecentlyAddedSection(),
                      for (final genre in _genres(state.library))
                        _GenreSection(genre: genre),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Genres shown as Home rows, capped so a large server does not fire
  /// dozens of album queries at once.
  static List<LibraryItem> _genres(List<LibraryItem> library) {
    return library
        .where((item) => item.type == LibraryItemType.genre)
        .take(12)
        .toList(growable: false);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.results});

  final List<LibraryItem> results;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (results.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('No matches in this library.')),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      sliver: SliverList.separated(
        itemCount: results.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = results[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            leading: SizedBox.square(
              dimension: 52,
              child: Artwork(item: item, borderRadius: 10, iconSize: 24),
            ),
            title: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              item.subtitle ?? item.type.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => item.type == LibraryItemType.track
                ? ref.read(appControllerProvider.notifier).play(item)
                : context.push('/item/${item.id}'),
          );
        },
      ),
    );
  }
}

class _RecentlyAddedSection extends ConsumerWidget {
  const _RecentlyAddedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentlyAddedProvider).value ?? const [];
    if (recent.isEmpty) return const SizedBox.shrink();
    return _MediaSection(
      title: 'Recently added',
      subtitle: 'New on your server',
      items: recent,
      showAllPath: '/browse/album',
    );
  }
}

class _GenreSection extends ConsumerWidget {
  const _GenreSection({required this.genre});

  final LibraryItem genre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(genreAlbumsProvider(genre.id)).value ?? const [];
    if (albums.isEmpty) return const SizedBox.shrink();
    return _MediaSection(
      title: genre.name,
      subtitle: 'Albums in this genre',
      items: albums,
      showAllPath: '/item/${genre.id}',
    );
  }
}

class _MediaSection extends ConsumerWidget {
  const _MediaSection({
    required this.title,
    required this.subtitle,
    required this.items,
    this.showAllPath,
  });

  final String title;
  final String subtitle;
  final List<LibraryItem> items;
  final String? showAllPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              if (showAllPath != null)
                TextButton(
                  onPressed: () => context.push(showAllPath!),
                  child: const Text(
                    'Show all',
                    style: TextStyle(color: JamColors.muted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: JamColors.muted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 236,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return ArtworkCard(
                  item: item,
                  onPlay: () async {
                    final controller = ref.read(appControllerProvider.notifier);
                    if (item.type == LibraryItemType.track) {
                      await controller.play(item);
                      return;
                    }
                    final children = await ref.read(
                      childrenProvider(item.id).future,
                    );
                    final tracks = children
                        .where((child) => child.type == LibraryItemType.track)
                        .toList(growable: false);
                    if (tracks.isNotEmpty) await controller.playQueue(tracks);
                  },
                  onTap: () {
                    if (item.type == LibraryItemType.track) {
                      ref.read(appControllerProvider.notifier).play(item);
                    } else {
                      context.push('/item/${item.id}');
                    }
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

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2030),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.cloud_off_rounded,
          color: JamColors.accentBright,
        ),
        title: const Text('Using your cached library'),
        subtitle: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          tooltip: 'Dismiss',
          onPressed: onDismiss,
          icon: const Icon(Icons.close_rounded),
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Icon(Icons.library_music_outlined, size: 64, color: JamColors.muted),
          SizedBox(height: 18),
          Text('No music found on this server.'),
        ],
      ),
    );
  }
}
