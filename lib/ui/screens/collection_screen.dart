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
        .where(
          (item) => item.type == LibraryItemType.track && item.isFavorite,
        )
        .length;
    final playlists = state.library
        .where((item) => item.type == LibraryItemType.playlist)
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Music',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: JamColors.ink,
        actions: [
          IconButton(
            tooltip: 'Downloads',
            onPressed: () => context.go('/downloads'),
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
        children: [
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
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
              ),
            ),
            title: const Text('Liked Songs'),
            subtitle: Text('$likedCount songs'),
            onTap: () => context.go('/liked'),
          ),
          const Divider(height: 18),
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
