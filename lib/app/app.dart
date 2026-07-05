import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/router.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/platform/discord_presence.dart';
import 'package:jamhorse/platform/window_decorations.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/window_frame.dart';

class JamHorseApp extends ConsumerWidget {
  const JamHorseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        if (!supportsWindowDecorations || !customDecorations || authenticated) {
          return child ?? const SizedBox.shrink();
        }
        return ColoredBox(
          color: JamColors.ink,
          child: Column(
            children: [
              const StandaloneWindowCaption(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          ),
        );
      },
    );
  }
}
