import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/platform/window_decorations.dart';
import 'package:jamhorse/ui/layout.dart';
import 'package:jamhorse/ui/shell/desktop_shell.dart';
import 'package:jamhorse/ui/widgets/mini_player.dart';
import 'package:jamhorse/ui/widgets/window_frame.dart';

/// Picks the three-panel desktop layout or Spotify's phone layout with a
/// mini player above Home / Search / Your Library tabs.
class AdaptiveShell extends ConsumerWidget {
  const AdaptiveShell({required this.child, super.key});

  final Widget child;

  static const _tabs = [
    _Tab('Home', Icons.home_outlined, Icons.home_filled, '/home'),
    _Tab(
      'Search',
      Icons.search_rounded,
      Icons.manage_search_rounded,
      '/search',
    ),
    _Tab(
      'Your Library',
      Icons.library_music_outlined,
      Icons.library_music_rounded,
      '/collection',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final customDecorations =
        supportsWindowDecorations &&
        ref.watch(windowDecorationProvider) == WindowDecorationMode.custom;
    if (isDesktopLayout(context)) {
      return DesktopShell(
        path: path,
        customDecorations: customDecorations,
        child: child,
      );
    }
    final selected = path.startsWith('/search')
        ? 1
        : path.startsWith('/collection') ||
              path.startsWith('/liked') ||
              path.startsWith('/downloads')
        ? 2
        : 0;
    final scaffold = Scaffold(
      backgroundColor: JamColors.ink,
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: selected,
            onDestinationSelected: (index) => context.go(_tabs[index].path),
            destinations: [
              for (final tab in _tabs)
                NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.selectedIcon),
                  label: tab.label,
                ),
            ],
          ),
        ],
      ),
    );
    if (!customDecorations) return scaffold;
    // The compact layout has no top bar, so it needs its own caption to keep
    // the window movable and closable.
    return Column(
      children: [
        const StandaloneWindowCaption(),
        Expanded(child: scaffold),
      ],
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon, this.path);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}
