import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/screens/browse_screen.dart';
import 'package:jamhorse/ui/screens/collection_screen.dart';
import 'package:jamhorse/ui/screens/downloads_screen.dart';
import 'package:jamhorse/ui/screens/home_screen.dart';
import 'package:jamhorse/ui/screens/item_detail_screen.dart';
import 'package:jamhorse/ui/screens/liked_songs_screen.dart';
import 'package:jamhorse/ui/screens/login_screen.dart';
import 'package:jamhorse/ui/screens/now_playing_screen.dart';
import 'package:jamhorse/ui/screens/settings_screen.dart';
import 'package:jamhorse/ui/shell/adaptive_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(
    appControllerProvider.select(
      (state) => (state.initializing, state.isAuthenticated),
    ),
  );
  return GoRouter(
    initialLocation: auth.$1 ? '/splash' : auth.$2 ? '/home' : '/login',
    redirect: (context, routerState) {
      final location = routerState.matchedLocation;
      if (auth.$1) return location == '/splash' ? null : '/splash';
      if (!auth.$2) return location == '/login' ? null : '/login';
      if (location == '/login' || location == '/splash') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdaptiveShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/liked',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LikedSongsScreen()),
          ),
          GoRoute(
            path: '/collection',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CollectionScreen()),
          ),
          GoRoute(
            path: '/downloads',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DownloadsScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
          GoRoute(
            path: '/browse/:type',
            builder: (context, state) =>
                BrowseScreen(typeName: state.pathParameters['type']!),
          ),
          GoRoute(
            path: '/item/:id',
            builder: (context, state) =>
                ItemDetailScreen(itemId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/now-playing',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          child: NowPlayingScreen(
            initialTab: state.uri.queryParameters['tab'] ?? 'player',
          ),
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => context.go('/home'),
          child: const Text('Return home'),
        ),
      ),
    ),
  );
});
