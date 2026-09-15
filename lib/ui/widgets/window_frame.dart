import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/ui/widgets/brand.dart';
import 'package:window_manager/window_manager.dart';

class StandaloneWindowCaption extends StatelessWidget {
  const StandaloneWindowCaption({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kWindowCaptionHeight,
      child: ColoredBox(
        color: JamColors.ink,
        child: Row(
          children: [
            Expanded(
              child: DragToMoveArea(
                // Expands the drag surface to the full caption height instead
                // of just the logo row.
                child: SizedBox.expand(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Row(
                      children: [
                        const JamHorseMark(size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'JamHorse',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: JamColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const WindowControls(),
          ],
        ),
      ),
    );
  }
}

/// Whether the app draws its own hairline window border. macOS already
/// outlines frameless windows natively.
bool get drawsWindowEdge => Platform.isWindows || Platform.isLinux;

/// A faint light outline around a frameless window, as Spotify draws, so the
/// black window stands apart from what is behind it. Hidden while maximized
/// or full screen, where the window has no visible edge.
class WindowEdge extends StatefulWidget {
  const WindowEdge({required this.child, super.key});

  final Widget child;

  @override
  State<WindowEdge> createState() => _WindowEdgeState();
}

class _WindowEdgeState extends State<WindowEdge> with WindowListener {
  var _edgeless = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _refresh();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    final edgeless =
        await windowManager.isMaximized() || await windowManager.isFullScreen();
    if (mounted && edgeless != _edgeless) {
      setState(() => _edgeless = edgeless);
    }
  }

  @override
  void onWindowMaximize() => _refresh();

  @override
  void onWindowUnmaximize() => _refresh();

  @override
  void onWindowEnterFullScreen() => _refresh();

  @override
  void onWindowLeaveFullScreen() => _refresh();

  @override
  Widget build(BuildContext context) {
    // Painted over the content so the layout does not shift when the edge
    // appears or disappears.
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: _edgeless ? null : Border.all(color: JamColors.windowEdge),
      ),
      child: widget.child,
    );
  }
}

class WindowControls extends StatefulWidget {
  const WindowControls({super.key});

  @override
  State<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<WindowControls> with WindowListener {
  var _maximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _refreshMaximized();
  }

  Future<void> _refreshMaximized() async {
    final maximized = await windowManager.isMaximized();
    if (mounted) setState(() => _maximized = maximized);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() => _maximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 138,
      child: Row(
        children: [
          WindowCaptionButton.minimize(
            brightness: Brightness.dark,
            onPressed: windowManager.minimize,
          ),
          _maximized
              ? WindowCaptionButton.unmaximize(
                  brightness: Brightness.dark,
                  onPressed: windowManager.unmaximize,
                )
              : WindowCaptionButton.maximize(
                  brightness: Brightness.dark,
                  onPressed: windowManager.maximize,
                ),
          WindowCaptionButton.close(
            brightness: Brightness.dark,
            onPressed: windowManager.close,
          ),
        ],
      ),
    );
  }
}
