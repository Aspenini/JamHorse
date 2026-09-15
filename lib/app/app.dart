import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/router.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/core/logging.dart';
import 'package:jamhorse/platform/discord_presence.dart';
import 'package:jamhorse/platform/window_decorations.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/window_frame.dart';

class JamHorseApp extends ConsumerStatefulWidget {
  const JamHorseApp({super.key});

  @override
  ConsumerState<JamHorseApp> createState() => _JamHorseAppState();
}

class _JamHorseAppState extends ConsumerState<JamHorseApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: _reconcileDownloads,
      // Background, minimize, and quit are the last reliable moments to
      // save the queue before the OS may kill the process.
      onHide: _persistPlayback,
      onExitRequested: () async {
        await _persistPlayback();
        return AppExitResponse.exit;
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _reconcileDownloads());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _reconcileDownloads() async {
    try {
      await ref.read(downloadManagerProvider).reconcile();
    } catch (error) {
      appLog.warning('Download reconciliation failed: $error');
    }
  }

  Future<void> _persistPlayback() async {
    try {
      await ref.read(playbackCoordinatorProvider).persistNow();
    } catch (error) {
      appLog.warning('Playback state not saved on hide: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final authenticated = ref.watch(
      appControllerProvider.select((state) => state.isAuthenticated),
    );
    final customDecorations =
        ref.watch(windowDecorationProvider) == WindowDecorationMode.custom;
    // Instantiated here so presence updates flow without any screen using it.
    ref.watch(discordPresenceProvider);
    return MaterialApp.router(
      title: 'JamHorse',
      debugShowCheckedModeBanner: false,
      theme: buildJamHorseTheme(),
      routerConfig: router,
      builder: (context, child) {
        final frameless = supportsWindowDecorations && customDecorations;
        Widget content = child ?? const SizedBox.shrink();
        if (frameless && !authenticated) {
          content = ColoredBox(
            color: JamColors.ink,
            child: Column(
              children: [
                const StandaloneWindowCaption(),
                Expanded(child: content),
              ],
            ),
          );
        }
        return frameless && drawsWindowEdge
            ? WindowEdge(child: content)
            : content;
      },
    );
  }
}
