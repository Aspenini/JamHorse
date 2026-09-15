import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/state/navigation_history.dart';
import 'package:jamhorse/state/playback_providers.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/state/ui_state.dart';
import 'package:jamhorse/ui/shell/library_sidebar.dart';
import 'package:jamhorse/ui/shell/right_panel.dart';
import 'package:jamhorse/ui/widgets/interaction.dart';
import 'package:jamhorse/ui/widgets/player_bar.dart';
import 'package:jamhorse/ui/widgets/resize_handle.dart';
import 'package:jamhorse/ui/widgets/user_avatar.dart';
import 'package:jamhorse/ui/widgets/window_frame.dart';
import 'package:window_manager/window_manager.dart';

final _searchFocusProvider = Provider<FocusNode>((ref) {
  final node = FocusNode(debugLabel: 'Search');
  ref.onDispose(node.dispose);
  return node;
});

/// Width of each side of the top bar, leaving the search field centered.
const _topBarSideWidth = 220.0;

/// Spotify's three-panel desktop layout: library, content, and the
/// Now Playing / Queue / Lyrics panel, above the player bar. The gaps
/// between panels can be dragged to resize them.
class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({
    required this.path,
    required this.customDecorations,
    required this.child,
    super.key,
  });

  final String path;
  final bool customDecorations;
  final Widget child;

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell> {
  // Panel widths when the current drag began; the handle reports distance
  // from there, so the edge tracks the cursor even after passing a limit.
  double? _libraryDrag;
  double? _panelDrag;

  @override
  Widget build(BuildContext context) {
    final path = widget.path;
    final customDecorations = widget.customDecorations;
    final child = widget.child;
    final panel = ref.watch(rightPanelProvider);
    final sizes = resolvePanelSizes(
      windowWidth: MediaQuery.sizeOf(context).width,
      layout: ref.watch(panelLayoutProvider),
      rightPanelOpen: panel != null,
    );
    final panels = ref.read(panelLayoutProvider.notifier);
    final player = ref.read(playerControllerProvider);
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): player.togglePlay,
        SingleActivator(
          LogicalKeyboardKey.arrowRight,
          control: !mac,
          meta: mac,
        ): player.next,
        SingleActivator(LogicalKeyboardKey.arrowLeft, control: !mac, meta: mac):
            player.previous,
        SingleActivator(
          LogicalKeyboardKey.keyK,
          control: !mac,
          meta: mac,
        ): () =>
            ref.read(_searchFocusProvider).requestFocus(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: JamColors.ink,
          body: Column(
            children: [
              _TopBar(
                path: path,
                sideWidth: _topBarSideWidth,
                customDecorations: customDecorations,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: sizes.library,
                        child: SpotifyPanel(
                          child: LibrarySidebar(
                            path: path,
                            collapsed: sizes.libraryCollapsed,
                          ),
                        ),
                      ),
                      ResizeHandle(
                        key: const ValueKey('library-resize-handle'),
                        onDragStart: () => _libraryDrag = sizes.library,
                        onDragUpdate: (dx) => panels.dragLibraryTo(
                          (_libraryDrag ?? sizes.library) + dx,
                          widthBeforeDrag: _libraryDrag,
                        ),
                        onDragEnd: () {
                          _libraryDrag = null;
                          panels.save();
                        },
                        onDoubleTap: panels.resetLibrary,
                      ),
                      Expanded(
                        child: SpotifyPanel(
                          child: EntranceMotion(watchKey: path, child: child),
                        ),
                      ),
                      _RightPanelDrawer(
                        width: sizes.rightPanel,
                        view: panel,
                        // Width changes follow the pointer instantly while
                        // dragging; opening and closing still animate.
                        animate: _panelDrag == null,
                        handle: ResizeHandle(
                          key: const ValueKey('right-panel-resize-handle'),
                          onDragStart: () =>
                              setState(() => _panelDrag = sizes.rightPanel),
                          // The handle is on the panel's left edge, so
                          // moving left widens it.
                          onDragUpdate: (dx) => panels.setRightPanelWidth(
                            (_panelDrag ?? sizes.rightPanel) - dx,
                          ),
                          onDragEnd: () {
                            setState(() => _panelDrag = null);
                            panels.save();
                          },
                          onDoubleTap: panels.resetRightPanel,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const PlayerBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RightPanelDrawer extends StatefulWidget {
  const _RightPanelDrawer({
    required this.width,
    required this.view,
    required this.handle,
    this.animate = true,
  });

  final double width;
  final RightPanelView? view;
  final Widget handle;
  final bool animate;

  @override
  State<_RightPanelDrawer> createState() => _RightPanelDrawerState();
}

class _RightPanelDrawerState extends State<_RightPanelDrawer> {
  // Keeps the outgoing panel on screen while the drawer slides closed, and
  // stops building it at all once fully closed.
  late RightPanelView _shown = widget.view ?? RightPanelView.nowPlaying;
  late bool _mounted = widget.view != null;

  @override
  void didUpdateWidget(covariant _RightPanelDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.view case final view?) {
      _shown = view;
      _mounted = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final open = widget.view != null;
    // The 8px resize handle travels with the drawer.
    final fullWidth = widget.width + 8;
    return AnimatedContainer(
      duration: widget.animate
          ? const Duration(milliseconds: 260)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      width: open ? fullWidth : 0,
      onEnd: () {
        if (!open && _mounted) setState(() => _mounted = false);
      },
      child: !_mounted
          ? null
          : ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: fullWidth,
                maxWidth: fullWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    widget.handle,
                    Expanded(
                      child: SpotifyPanel(child: RightPanel(view: _shown)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _TopBar extends ConsumerStatefulWidget {
  const _TopBar({
    required this.path,
    required this.sideWidth,
    required this.customDecorations,
  });

  final String path;
  final double sideWidth;
  final bool customDecorations;

  @override
  ConsumerState<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends ConsumerState<_TopBar> {
  final _controller = TextEditingController();
  late final FocusNode _focusNode = ref.read(_searchFocusProvider);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) _openSearch();
  }

  void _openSearch() {
    if (widget.path != '/search') context.go('/search');
  }

  void _onChanged(String value) {
    ref.read(searchQueryProvider.notifier).set(value);
    _openSearch();
  }

  void _navigateHistory({required bool back}) {
    final history = ref.read(navigationHistoryProvider.notifier);
    final target = back ? history.goBack() : history.goForward();
    if (target != null) context.go(target);
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
    final history = ref.watch(navigationHistoryProvider);
    final onHome = widget.path == '/home';
    return SizedBox(
      height: 64,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Empty stretches of the bar drag the window, like a title bar.
          if (widget.customDecorations)
            const DragToMoveArea(child: SizedBox.expand()),
          Row(
            children: [
              SizedBox(
                width: widget.sideWidth,
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const _AppMenuButton(),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Go back',
                      onPressed: history.canGoBack
                          ? () => _navigateHistory(back: true)
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded, size: 30),
                    ),
                    IconButton(
                      tooltip: 'Go forward',
                      onPressed: history.canGoForward
                          ? () => _navigateHistory(back: false)
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded, size: 30),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HoverScale(
                      hoverScale: 1.06,
                      child: IconButton.filled(
                        tooltip: 'Home',
                        onPressed: () => context.go('/home'),
                        style: IconButton.styleFrom(
                          backgroundColor: JamColors.soft,
                          foregroundColor: onHome
                              ? Colors.white
                              : JamColors.muted,
                          minimumSize: const Size.square(48),
                        ),
                        icon: Icon(
                          onHome ? Icons.home_filled : Icons.home_outlined,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 480,
                          maxHeight: 48,
                        ),
                        child: SearchBar(
                          controller: _controller,
                          focusNode: _focusNode,
                          hintText: 'What do you want to play?',
                          leading: const Icon(Icons.search_rounded, size: 26),
                          trailing: [
                            if (query.isNotEmpty)
                              IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _controller.clear();
                                  ref
                                      .read(searchQueryProvider.notifier)
                                      .set('');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                          ],
                          onTap: _openSearch,
                          onChanged: _onChanged,
                          onSubmitted: _onChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: widget.sideWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
                                child: UserAvatar(size: 32),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: widget.customDecorations ? 8 : 16),
                    if (widget.customDecorations) const WindowControls(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _AppAction { settings, downloads, refresh, signOut }

class _AppMenuButton extends ConsumerWidget {
  const _AppMenuButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_AppAction>(
      tooltip: 'Menu',
      icon: const Icon(Icons.more_horiz_rounded, color: JamColors.muted),
      color: const Color(0xFF282828),
      onSelected: (action) {
        final controller = ref.read(appControllerProvider.notifier);
        switch (action) {
          case _AppAction.settings:
            context.go('/settings');
          case _AppAction.downloads:
            context.go('/downloads');
          case _AppAction.refresh:
            controller.synchronize();
          case _AppAction.signOut:
            controller.logout();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: _AppAction.settings, child: Text('Settings')),
        PopupMenuItem(value: _AppAction.downloads, child: Text('Downloads')),
        PopupMenuItem(
          value: _AppAction.refresh,
          child: Text('Refresh library'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(value: _AppAction.signOut, child: Text('Log out')),
      ],
    );
  }
}
