import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/ui/widgets/item_menu.dart';
import 'package:jamhorse/ui/widgets/library_tiles.dart';

/// Desktop "Your Library" sidebar.
class LibrarySidebar extends ConsumerWidget {
  const LibrarySidebar({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Your Library',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _createPlaylist(context),
                style: FilledButton.styleFrom(
                  backgroundColor: JamColors.soft,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Create'),
              ),
            ],
          ),
        ),
        const LibraryToolbar(padding: EdgeInsets.symmetric(horizontal: 12)),
        Expanded(
          child: LibraryEntriesView(selectedPath: path, onNavigate: context.go),
        ),
      ],
    );
  }

  Future<void> _createPlaylist(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final playlist = await showCreatePlaylistDialog(context, container);
    if (playlist != null && context.mounted) {
      context.go('/item/${playlist.id}');
    }
  }
}
