import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/library_index.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/layout.dart';
import 'package:jamhorse/ui/navigation.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';
import 'package:jamhorse/ui/widgets/artwork_color.dart';
import 'package:jamhorse/ui/widgets/hoverable.dart';
import 'package:jamhorse/ui/widgets/item_menu.dart';
import 'package:jamhorse/ui/widgets/media_row.dart';
import 'package:jamhorse/ui/widgets/user_avatar.dart';

/// Albums and playlists behind recently played tracks, most recent first.
final _recentContextsProvider = Provider<List<LibraryItem>>((ref) {
  final recent = ref.watch(recentlyPlayedProvider).value ?? const [];
  final index = ref.watch(libraryIndexProvider);
  final seen = <String>{};
  return [
    for (final track in recent)
      if ((index.byId[track.albumId] ?? track) case final entry
          when seen.add(entry.id))
        entry,
  ];
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = isDesktopLayout(context);
    final syncing = ref.watch(appControllerProvider.select((s) => s.syncing));
    final error = ref.watch(appControllerProvider.select((s) => s.error));
    final libraryEmpty = ref.watch(
      libraryIndexProvider.select((index) => index.byId.isEmpty),
    );
    final genres = ref.watch(libraryIndexProvider.select((i) => i.genres));
    final recent = ref.watch(_recentContextsProvider);
    final recentlyAdded = ref.watch(recentlyAddedProvider).value ?? const [];
    final controller = ref.read(appControllerProvider.notifier);
    final tint = ref.artworkColor(
      recent.firstOrNull,
      fallback: const Color(0xFF2A2A2A),
    );
    final side = desktop ? 24.0 : 16.0;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: JamColors.accent,
        onRefresh: controller.synchronize,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [tint, JamColors.elevated],
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  side,
                  (desktop ? 16 : 12) + MediaQuery.paddingOf(context).top,
                  side,
                  8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!desktop) ...[
                          const ProfileButton(),
                          const SizedBox(width: 12),
                        ],
                        const Expanded(child: _Chips()),
                        if (syncing)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        IconButton(
                          tooltip: 'Shuffle your library',
                          onPressed: controller.shuffleAll,
                          icon: const Icon(Icons.shuffle_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _greeting(),
                      style: desktop
                          ? Theme.of(context).textTheme.headlineLarge
                          : Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    _ShortcutGrid(recent: recent, desktop: desktop),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(side - 12, 24, side - 12, 40),
              sliver: SliverList.list(
                children: [
                  if (error != null)
                    _OfflineBanner(
                      message: error,
                      onDismiss: controller.clearError,
                    ),
                  if (libraryEmpty && !syncing)
                    const _EmptyLibrary()
                  else ...[
                    MediaRow(title: 'Recently played', items: recent),
                    MediaRow(
                      title: 'Recently added',
                      subtitle: 'New on your server',
                      items: recentlyAdded,
                      onShowAll: () => context.push('/browse/album'),
                    ),
                    // Capped so a large server does not fire dozens of
                    // album queries at once.
                    for (final genre in genres.take(10))
                      _GenreRow(genre: genre),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class _Chips extends StatelessWidget {
  const _Chips();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: true,
            showCheckmark: false,
            onSelected: (_) {},
          ),
          for (final (label, path) in const [
            ('Albums', '/browse/album'),
            ('Artists', '/browse/artist'),
            ('Playlists', '/browse/playlist'),
          ])
            ActionChip(label: Text(label), onPressed: () => context.push(path)),
        ],
      ),
    );
  }
}

/// Spotify's compact grid of quick picks at the top of Home.
class _ShortcutGrid extends ConsumerWidget {
  const _ShortcutGrid({required this.recent, required this.desktop});

  final List<LibraryItem> recent;
  final bool desktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(libraryIndexProvider.select((i) => i.likedTracks));
    final controller = ref.read(appControllerProvider.notifier);
    final picks = recent.take(desktop ? 7 : 5).toList(growable: false);
    final tiles = <Widget>[
      _ShortcutTile(
        title: 'Liked Songs',
        artwork: const LikedSongsArt(iconSize: 22),
        onTap: () => context.push('/liked'),
        onPlay: liked.isEmpty ? null : () => controller.playQueue(liked),
      ),
      for (final item in picks)
        _ShortcutTile(
          item: item,
          title: item.name,
          artwork: Artwork(item: item, borderRadius: 0, iconSize: 22),
          onTap: () => item.type == LibraryItemType.track
              ? controller.play(item)
              : openItem(context, item),
          onPlay: () => controller.play(item),
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 56,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, index) => tiles[index],
        );
      },
    );
  }
}

class _ShortcutTile extends ConsumerWidget {
  const _ShortcutTile({
    required this.title,
    required this.artwork,
    required this.onTap,
    this.item,
    this.onPlay,
  });

  final String title;
  final Widget artwork;
  final VoidCallback onTap;
  final LibraryItem? item;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = item;
    return Hoverable(
      borderRadius: 4,
      semanticLabel: title,
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
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: hovered ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            SizedBox.square(dimension: 56, child: artwork),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onPlay != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PlayOverlayButton(
                  visible: hovered,
                  size: 34,
                  onPressed: onPlay!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GenreRow extends ConsumerWidget {
  const _GenreRow({required this.genre});

  final LibraryItem genre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(genreAlbumsProvider(genre.id)).value ?? const [];
    return MediaRow(
      title: genre.name,
      items: albums,
      onShowAll: () => openItem(context, genre),
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
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2030),
        borderRadius: BorderRadius.circular(8),
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
