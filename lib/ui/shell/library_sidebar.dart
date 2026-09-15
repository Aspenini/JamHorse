import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/state/ui_state.dart';
import 'package:jamhorse/ui/widgets/item_menu.dart';
import 'package:jamhorse/ui/widgets/library_tiles.dart';

/// Desktop "Your Library" sidebar, or its artwork-only rail when collapsed.
class LibrarySidebar extends ConsumerWidget {
  const LibrarySidebar({required this.path, super.key, this.collapsed = false});

  final String path;
  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panels = ref.read(panelLayoutProvider.notifier);
    if (collapsed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          IconButton(
            tooltip: 'Expand Your Library',
            onPressed: panels.toggleLibrary,
            icon: const Icon(Icons.library_music_rounded),
          ),
          IconButton(
            tooltip: 'Create playlist',
            onPressed: () => _createPlaylist(context),
            icon: const Icon(Icons.add_rounded),
          ),
          Expanded(
            child: LibraryRail(selectedPath: path, onNavigate: context.go),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Tooltip(
                    message: 'Collapse Your Library',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: panels.toggleLibrary,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          'Your Library',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                  ),
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
