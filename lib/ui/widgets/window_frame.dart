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
