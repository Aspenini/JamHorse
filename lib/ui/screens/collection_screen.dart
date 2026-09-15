import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/ui/widgets/item_menu.dart';
import 'package:jamhorse/ui/widgets/library_tiles.dart';
import 'package:jamhorse/ui/widgets/user_avatar.dart';

/// The phone "Your Library" tab, sharing its filters, sort, and layout with
/// the desktop sidebar.
class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: JamColors.ink,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  const ProfileButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your Library',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Create playlist',
                    iconSize: 28,
                    onPressed: () => _createPlaylist(context),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
            const LibraryToolbar(),
            Expanded(
              child: LibraryEntriesView(
                onNavigate: (path) => context.push(path),
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 120),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPlaylist(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final playlist = await showCreatePlaylistDialog(context, container);
    if (playlist != null && context.mounted) {
      await context.push('/item/${playlist.id}');
    }
  }
}
