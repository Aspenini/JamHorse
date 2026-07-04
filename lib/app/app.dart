import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/router.dart';
import 'package:jamhorse/app/theme.dart';

class JamHorseApp extends ConsumerWidget {
  const JamHorseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'JamHorse',
      debugShowCheckedModeBanner: false,
      theme: buildJamHorseTheme(),
      routerConfig: router,
    );
  }
}
