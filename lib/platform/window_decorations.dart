import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

enum WindowDecorationMode { native, custom }

const _preferenceKey = 'windowDecorationMode';
var _initialMode = WindowDecorationMode.custom;

bool get supportsWindowDecorations =>
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;

Future<WindowDecorationMode> loadWindowDecorationMode() async {
  if (!supportsWindowDecorations) return WindowDecorationMode.native;
  final preferences = await SharedPreferences.getInstance();
  final saved = preferences.getString(_preferenceKey);
  return WindowDecorationMode.values.firstWhere(
    (mode) => mode.name == saved,
    orElse: () => WindowDecorationMode.custom,
  );
}

void seedWindowDecorationMode(WindowDecorationMode mode) {
  _initialMode = mode;
}

final windowDecorationProvider =
    NotifierProvider<WindowDecorationController, WindowDecorationMode>(
      WindowDecorationController.new,
    );

class WindowDecorationController extends Notifier<WindowDecorationMode> {
  @override
  WindowDecorationMode build() => _initialMode;

  Future<void> setMode(WindowDecorationMode mode) async {
    if (!supportsWindowDecorations || state == mode) return;
    state = mode;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, mode.name);
    await windowManager.setTitleBarStyle(
      mode == WindowDecorationMode.custom
          ? TitleBarStyle.hidden
          : TitleBarStyle.normal,
      windowButtonVisibility: mode == WindowDecorationMode.native,
    );
  }
}
