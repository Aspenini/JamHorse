import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';
import 'package:jamhorse/ui/widgets/brand.dart';
import 'package:jamhorse/ui/widgets/interaction.dart';
import 'package:jamhorse/ui/widgets/mini_player.dart';

class AdaptiveShell extends ConsumerWidget {
  const AdaptiveShell({required this.child, super.key});

  final Widget child;

  static const _mobileDestinations = [
    _Destination('Home', Icons.home_filled, '/home'),
    _Destination('Your Library', Icons.library_music_rounded, '/collection'),
    _Destination('Settings', Icons.settings_rounded, '/settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 920;
    final path = GoRouterState.of(context).uri.path;
    if (desktop) {
      return _SpotifyDesktopShell(path: path, child: child);
    }
    final selected = _mobileDestinations
        .indexWhere((destination) => path.startsWith(destination.path))
        .clamp(0, _mobileDestinations.length - 1);
    return Scaffold(
      backgroundColor: JamColors.ink,
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: selected,
            onDestinationSelected: (index) =>
                context.go(_mobileDestinations[index].path),
            destinations: _mobileDestinations
                .map(
                  (destination) => NavigationDestination(
                    icon: Icon(destination.icon),
                    label: destination.label,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _SpotifyDesktopShell extends StatelessWidget {
  const _SpotifyDesktopShell({required this.path, required this.child});

  final String path;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showNowPlaying = width >= 1520;
    final libraryWidth = width >= 1900
        ? 510.0
        : width >= 1320
        ? 360.0
        : 300.0;
    final nowPlayingWidth = (width * 0.265).clamp(360.0, 500.0);
    return Scaffold(
      backgroundColor: JamColors.ink,
      body: Column(
        children: [
          _GlobalTopBar(libraryWidth: libraryWidth),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: libraryWidth,
                    child: SpotifyPanel(child: _LibraryPanel(path: path)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SpotifyPanel(
                      child: EntranceMotion(watchKey: path, child: child),
                    ),
                  ),
                  if (showNowPlaying) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: nowPlayingWidth,
                      child: const SpotifyPanel(child: _NowPlayingPanel()),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const PlayerBar(),
        ],
      ),
    );
  }
}

class _GlobalTopBar extends ConsumerStatefulWidget {
  const _GlobalTopBar({required this.libraryWidth});

  final double libraryWidth;

  @override
  ConsumerState<_GlobalTopBar> createState() => _GlobalTopBarState();
}

class _GlobalTopBarState extends ConsumerState<_GlobalTopBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search(String value) {
    ref.read(searchQueryProvider.notifier).set(value);
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 260),
      () => ref.read(appControllerProvider.notifier).search(value),
    );
    if (GoRouterState.of(context).uri.path != '/home') context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    if (!_focusNode.hasFocus && _controller.text != query) {
      _controller.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          SizedBox(
            width: widget.libraryWidth,
            child: Row(
              children: [
                const SizedBox(width: 18),
                const Icon(Icons.more_horiz_rounded, color: JamColors.muted),
                const SizedBox(width: 24),
                IconButton(
                  tooltip: 'Back',
                  onPressed: context.canPop() ? context.pop : null,
                  icon: const Icon(Icons.chevron_left_rounded, size: 34),
                ),
                IconButton(
                  tooltip: 'Forward',
                  onPressed: null,
                  icon: const Icon(Icons.chevron_right_rounded, size: 34),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CircleButton(
                  tooltip: 'Home',
                  icon: Icons.home_filled,
                  onPressed: () => context.go('/home'),
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 710),
                  child: SearchBar(
                    controller: _controller,
                    focusNode: _focusNode,
                    hintText: 'What do you want to play?',
                    leading: const Icon(Icons.search_rounded, size: 30),
                    trailing: [
                      if (query.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _controller.clear();
                            _search('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        )
                      else ...[
                        const SizedBox(
                          height: 30,
                          child: VerticalDivider(color: JamColors.subtle),
                        ),
                        const Icon(Icons.inventory_2_outlined, size: 25),
                      ],
                    ],
                    onChanged: _search,
                    onSubmitted: _search,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: widget.libraryWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                IconButton(
                  tooltip: 'Friend activity',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Friend activity is not available on Jellyfin.',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.group_outlined),
                ),
                const SizedBox(width: 8),
                HoverScale(
                  hoverScale: 1.08,
                  child: Tooltip(
                    message: 'Profile and settings',
                    child: Material(
                      color: JamColors.soft,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.go('/settings'),
                        child: const SizedBox.square(
                          dimension: 44,
                          child: Padding(
                            padding: EdgeInsets.all(6),
                            child: ClipOval(child: JamHorseBrand(height: 32)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return HoverScale(
      hoverScale: 1.07,
      child: IconButton.filled(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: JamColors.soft,
          foregroundColor: Colors.white,
          minimumSize: const Size.square(52),
        ),
        icon: Icon(icon, size: 27),
      ),
    );
  }
}

class _LibraryPanel extends ConsumerWidget {
  const _LibraryPanel({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final likedCount = state.library
        .where((item) => item.type == LibraryItemType.track && item.isFavorite)
        .length;
    final likedTracks = state.library
        .where((item) => item.type == LibraryItemType.track && item.isFavorite)
        .toList(growable: false);
    final downloadedIds = ref.watch(downloadedItemIdsProvider);
    final downloadedTracks = state.library
        .where(
          (item) =>
              item.type == LibraryItemType.track &&
              downloadedIds.contains(item.id),
        )
        .toList(growable: false);
    final controller = ref.read(appControllerProvider.notifier);
    final libraryItems = state.library
        .where(
          (item) =>
              item.type == LibraryItemType.playlist ||
              item.type == LibraryItemType.album,
        )
        .take(16)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 18, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Your Library',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => context.go('/collection'),
                style: FilledButton.styleFrom(
                  backgroundColor: JamColors.soft,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                icon: const Icon(Icons.add_rounded, size: 24),
                label: const Text('Create'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                label: 'Playlists',
                selected: path.contains('/item/'),
                onTap: () => context.go('/collection'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Albums',
                selected: path == '/browse/album',
                onTap: () => context.go('/browse/album'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Artists',
                selected: path == '/browse/artist',
                onTap: () => context.go('/browse/artist'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Downloaded',
                selected: path == '/downloads',
                onTap: () => context.go('/downloads'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Search your library',
                onPressed: () {},
                icon: const Icon(Icons.search_rounded),
              ),
              const Spacer(),
              const Text(
                'Recents',
                style: TextStyle(
                  color: JamColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 7),
              const Icon(
                Icons.grid_view_rounded,
                size: 19,
                color: JamColors.muted,
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth >= 470
                  ? 3
                  : constraints.maxWidth >= 280
                  ? 2
                  : 1;
              final tiles = <Widget>[
                _LibraryCard(
                  title: 'Liked Songs',
                  subtitle: '$likedCount songs',
                  selected: path == '/liked',
                  onTap: () => context.go('/liked'),
                  onPlay: likedTracks.isEmpty
                      ? null
                      : () => controller.playQueue(likedTracks),
                  artwork: const _LikedArtwork(),
                ),
                _LibraryCard(
                  title: 'Downloads',
                  subtitle: 'Saved music',
                  selected: path == '/downloads',
                  onTap: () => context.go('/downloads'),
                  onPlay: downloadedTracks.isEmpty
                      ? null
                      : () => controller.playQueue(downloadedTracks),
                  artwork: const _DownloadArtwork(),
                ),
                for (final item in libraryItems)
                  _LibraryCard(
                    title: item.name,
                    subtitle: item.type == LibraryItemType.playlist
                        ? 'Playlist'
                        : item.subtitle ?? 'Album',
                    selected: path == '/item/${item.id}',
                    onTap: () => context.go('/item/${item.id}'),
                    onPlay: () async {
                      final children = await ref.read(
                        childrenProvider(item.id).future,
                      );
                      final tracks = children
                          .where((child) => child.type == LibraryItemType.track)
                          .toList(growable: false);
                      if (tracks.isNotEmpty) {
                        await controller.playQueue(tracks);
                      }
                    },
                    artwork: Artwork(item: item, borderRadius: 6, iconSize: 32),
                  ),
              ];
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: count,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.76,
                ),
                itemCount: tiles.length,
                itemBuilder: (context, index) => tiles[index],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    );
  }
}

class _LibraryCard extends StatefulWidget {
  const _LibraryCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.artwork,
    this.onPlay,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onPlay;
  final Widget artwork;

  @override
  State<_LibraryCard> createState() => _LibraryCardState();
}

class _LibraryCardState extends State<_LibraryCard> {
  var _hovered = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selected,
      label: '${widget.title}, ${widget.subtitle}',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: AnimatedScale(
          scale: _pressed
              ? 0.975
              : _hovered
              ? 1.018
              : 1,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            borderRadius: BorderRadius.circular(8),
            mouseCursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _hovered
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: widget.artwork,
                          ),
                          if (widget.onPlay != null)
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: AnimatedSlide(
                                duration: const Duration(milliseconds: 170),
                                curve: Curves.easeOutCubic,
                                offset: _hovered
                                    ? Offset.zero
                                    : const Offset(0, 0.25),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 130),
                                  opacity: _hovered ? 1 : 0,
                                  child: Material(
                                    color: JamColors.accent,
                                    elevation: 7,
                                    shadowColor: Colors.black87,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      onTap: widget.onPlay,
                                      customBorder: const CircleBorder(),
                                      child: const SizedBox.square(
                                        dimension: 42,
                                        child: Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.black,
                                          size: 27,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 130),
                    style: TextStyle(
                      color: widget.selected ? JamColors.accent : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
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
          ),
        ),
      ),
    );
  }
}

class _LikedArtwork extends StatelessWidget {
  const _LikedArtwork();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)],
        ),
      ),
      child: Center(
        child: Icon(Icons.favorite_rounded, color: Colors.white, size: 48),
      ),
    );
  }
}

class _DownloadArtwork extends StatelessWidget {
  const _DownloadArtwork();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF076653),
      child: Center(
        child: Icon(Icons.bookmark_rounded, color: JamColors.accent, size: 52),
      ),
    );
  }
}

class _NowPlayingPanel extends ConsumerWidget {
  const _NowPlayingPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinator = ref.watch(playbackCoordinatorProvider);
    final snapshot =
        ref.watch(playbackSnapshotProvider).value ??
        coordinator.currentSnapshot;
    final item = snapshot.queue.current;
    if (item == null) {
      return const EntranceMotion(
        watchKey: 'empty',
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              'Play something to see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: JamColors.muted),
            ),
          ),
        ),
      );
    }
    final related = ref
        .watch(appControllerProvider)
        .library
        .where(
          (candidate) =>
              candidate.id != item.id &&
              candidate.type == LibraryItemType.track &&
              (candidate.artistId == item.artistId ||
                  candidate.albumId == item.albumId),
        )
        .take(4)
        .toList(growable: false);
    return EntranceMotion(
      watchKey: item.id,
      child: ListView(
        key: ValueKey(item.id),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          Text(
            item.albumName ?? 'Now playing',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 28),
          HoverScale(
            hoverScale: 1.012,
            pressedScale: 1,
            child: AspectRatio(
              aspectRatio: 1,
              child: Artwork(item: item, borderRadius: 8, iconSize: 72),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.artists.isEmpty
                          ? item.subtitle ?? 'Unknown artist'
                          : item.artists.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: JamColors.muted,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: item.isFavorite
                    ? 'Remove from Liked Songs'
                    : 'Add to Liked Songs',
                onPressed: () => ref
                    .read(appControllerProvider.notifier)
                    .toggleFavorite(item),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    item.isFavorite
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    key: ValueKey(item.isFavorite),
                    color: item.isFavorite ? JamColors.accent : JamColors.muted,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: JamColors.soft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.album_outlined, color: JamColors.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.albumName ?? 'From your Jellyfin library',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          if (related.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text(
              'Related songs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            for (final candidate in related)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: SizedBox.square(
                  dimension: 48,
                  child: Artwork(
                    item: candidate,
                    borderRadius: 4,
                    iconSize: 20,
                  ),
                ),
                title: Text(
                  candidate.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  candidate.subtitle ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () =>
                    ref.read(appControllerProvider.notifier).play(candidate),
              ),
          ],
        ],
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
