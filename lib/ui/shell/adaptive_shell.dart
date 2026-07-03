import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';
import 'package:jamhorse/ui/widgets/brand.dart';
import 'package:jamhorse/ui/widgets/mini_player.dart';

class AdaptiveShell extends ConsumerWidget {
  const AdaptiveShell({required this.child, super.key});

  final Widget child;

  static const _mobileDestinations = [
    _Destination('Home', Icons.home_rounded, '/home'),
    _Destination('Your Music', Icons.library_music_rounded, '/collection'),
    _Destination('Settings', Icons.settings_rounded, '/settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 920;
    final path = GoRouterState.of(context).uri.path;
    if (desktop) {
      return Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  _Sidebar(path: path),
                  Expanded(child: child),
                ],
              ),
            ),
            const PlayerBar(),
          ],
        ),
      );
    }
    final selected = _mobileDestinations
        .indexWhere((destination) => path.startsWith(destination.path))
        .clamp(0, _mobileDestinations.length - 1);
    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: selected,
            onDestinationSelected: (index) =>
                context.go(_mobileDestinations[index].path),
            destinations: _mobileDestinations.map((destination) {
              return NavigationDestination(
                icon: Icon(destination.icon),
                label: destination.label,
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(
      appControllerProvider.select(
        (state) => state.library
            .where((item) => item.type == LibraryItemType.playlist)
            .toList(growable: false),
      ),
    );
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF090C15),
        border: Border(right: BorderSide(color: Color(0xFF1B2130))),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Row(
                children: [
                  const JamHorseBrand(height: 40),
                  const SizedBox(width: 10),
                  Text(
                    'JamHorse',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _SidebarItem(
                    label: 'Home',
                    icon: Icons.home_rounded,
                    selected: path.startsWith('/home'),
                    onTap: () => context.go('/home'),
                  ),
                  _SidebarItem(
                    label: 'Downloads',
                    icon: Icons.download_rounded,
                    selected: path.startsWith('/downloads'),
                    onTap: () => context.go('/downloads'),
                  ),
                  _SidebarItem(
                    label: 'Settings',
                    icon: Icons.settings_rounded,
                    selected: path.startsWith('/settings'),
                    onTap: () => context.go('/settings'),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                'YOUR LIBRARY',
                style: TextStyle(
                  color: JamColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: [
                  _SidebarTile(
                    selected: path == '/liked',
                    onTap: () => context.go('/liked'),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            JamColors.accentBright,
                            JamColors.accent,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    title: 'Liked Songs',
                    subtitle: 'Your Jellyfin favorites',
                  ),
                  for (final playlist in playlists)
                    _SidebarTile(
                      selected: path == '/item/${playlist.id}',
                      onTap: () => context.go('/item/${playlist.id}'),
                      leading: SizedBox.square(
                        dimension: 40,
                        child: Artwork(
                          item: playlist,
                          borderRadius: 8,
                          iconSize: 18,
                        ),
                      ),
                      title: playlist.name,
                      subtitle: 'Playlist',
                    ),
                  if (playlists.isEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(10, 12, 10, 0),
                      child: Text(
                        'Playlists you create in Jellyfin show up here.',
                        style: TextStyle(
                          color: JamColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? Colors.white : JamColors.muted,
              ),
              const SizedBox(width: 13),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : JamColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected ? const Color(0x1A6E96EC) : Colors.transparent,
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: JamColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
}
