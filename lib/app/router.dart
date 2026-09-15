import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/navigation_history.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/screens/browse_screen.dart';
import 'package:jamhorse/ui/screens/collection_screen.dart';
import 'package:jamhorse/ui/screens/downloads_screen.dart';
import 'package:jamhorse/ui/screens/home_screen.dart';
import 'package:jamhorse/ui/screens/item_detail_screen.dart';
import 'package:jamhorse/ui/screens/liked_songs_screen.dart';
import 'package:jamhorse/ui/screens/login_screen.dart';
import 'package:jamhorse/ui/screens/now_playing_screen.dart';
import 'package:jamhorse/ui/screens/search_screen.dart';
import 'package:jamhorse/ui/screens/settings_screen.dart';
import 'package:jamhorse/ui/shell/adaptive_shell.dart';

typedef _AuthGate = ({bool initializing, bool authenticated});

/// Built once for the app's lifetime. Sign-in changes re-run the redirect
/// through [GoRouter.refreshListenable] instead of replacing the router,
/// which would discard the navigation stack.
final routerProvider = Provider<GoRouter>((ref) {
  _AuthGate gate(AppState state) =>
      (initializing: state.initializing, authenticated: state.isAuthenticated);
  final auth = ValueNotifier<_AuthGate>(gate(ref.read(appControllerProvider)));
  ref.listen(
    appControllerProvider.select(gate),
    (_, next) => auth.value = next,
  );

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, routerState) {
      final location = routerState.matchedLocation;
      final (:initializing, :authenticated) = auth.value;
      if (initializing) return location == '/splash' ? null : '/splash';
      if (!authenticated) return location == '/login' ? null : '/login';
      if (location == '/login' || location == '/splash') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AdaptiveShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SearchScreen()),
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
            builder: (context, state) => ItemDetailScreen(
              itemId: state.pathParameters['id']!,
              fallback: state.extra is LibraryItem
                  ? state.extra! as LibraryItem
                  : null,
            ),
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

  void recordLocation() {
    final location = router.routerDelegate.currentConfiguration.uri.toString();
    final history = ref.read(navigationHistoryProvider.notifier);
    if (location.startsWith('/login') || location.startsWith('/splash')) {
      history.reset();
    } else {
      history.record(location);
    }
  }

  router.routerDelegate.addListener(recordLocation);
  ref.onDispose(() {
    router.routerDelegate.removeListener(recordLocation);
    router.dispose();
    auth.dispose();
  });
  return router;
});
