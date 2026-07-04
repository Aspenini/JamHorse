import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';

/// Mobile counterpart of the desktop sidebar: Liked Songs plus the user's
/// Jellyfin playlists.
class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final likedCount = state.library
        .where((item) => item.type == LibraryItemType.track && item.isFavorite)
        .length;
    final playlists = state.library
        .where((item) => item.type == LibraryItemType.playlist)
        .toList(growable: false);
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 120),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your Library',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              IconButton(
                tooltip: 'Downloads',
                onPressed: () => context.go('/downloads'),
                icon: const Icon(Icons.download_for_offline_outlined),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _LibraryCategory(
                label: 'Albums',
                icon: Icons.album_rounded,
                path: '/browse/album',
              ),
              _LibraryCategory(
                label: 'Artists',
                icon: Icons.person_rounded,
                path: '/browse/artist',
              ),
              _LibraryCategory(
                label: 'Songs',
                icon: Icons.music_note_rounded,
                path: '/browse/track',
              ),
              _LibraryCategory(
                label: 'Genres',
                icon: Icons.graphic_eq_rounded,
                path: '/browse/genre',
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [JamColors.accentBright, JamColors.accent],
                ),
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white),
            ),
            title: const Text('Liked Songs'),
            subtitle: Text('$likedCount songs'),
            onTap: () => context.go('/liked'),
          ),
          const SizedBox(height: 12),
          if (playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Playlists you create in Jellyfin show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: JamColors.muted),
              ),
            )
          else
            for (final playlist in playlists)
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                hoverColor: JamColors.softHover,
                leading: SizedBox.square(
                  dimension: 52,
                  child: Artwork(
                    item: playlist,
                    borderRadius: 10,
                    iconSize: 22,
                  ),
                ),
                title: Text(
                  playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: const Text('Playlist'),
                onTap: () => context.push('/item/${playlist.id}'),
              ),
        ],
      ),
    );
  }
}

class _LibraryCategory extends StatelessWidget {
  const _LibraryCategory({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final String path;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 19),
      label: Text(label),
      onPressed: () => context.push(path),
    );
  }
}
