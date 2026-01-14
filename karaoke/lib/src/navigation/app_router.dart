import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:karaoke/src/navigation/routes.dart';
import 'package:karaoke/src/navigation/scaffold_with_nav_bar.dart';
import 'package:karaoke/src/services/app_service.dart';
import 'package:karaoke/src/ui/pages/home/view/home_view.dart';
import 'package:karaoke/src/ui/pages/account/view/account_view.dart';
import 'package:karaoke/src/ui/pages/splash/splash_view.dart';
import 'package:karaoke/src/ui/pages/tv/tv_view.dart';
import 'package:karaoke/src/ui/pages/dj/dj_view.dart';
import 'package:karaoke/src/ui/pages/bar/bar_view.dart';
import 'package:karaoke/src/ui/pages/settings/settings_view.dart';

// private navigators
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final class AppRouter {
  AppRouter._internal() {
    _appService = AppService.getInstance();
  }
  GoRouter get router => _goRouter;
  late AppService _appService;

  // Singleton
  static final AppRouter _instance = AppRouter._internal();
  static AppRouter getInstance() => _instance;

  late final GoRouter _goRouter = GoRouter(
    refreshListenable: _appService,
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.home,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          // Pages with the nav bar visible
          GoRoute(
            path: RouteNames.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: RouteNames.account,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AccountPage(),
            ),
          ),
          // TODO: Add other pages with the nav bar
        ]
      ),
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.tv,
        builder: (context, state) => const TvPage(),
      ),
      GoRoute(
        path: RouteNames.dj,
        builder: (context, state) => const DjPage(),
      ),
      GoRoute(
        path: RouteNames.bar,
        builder: (context, state) => const BarPage(),
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      // Add other pages here
    ],
    redirect: (BuildContext context, GoRouterState state) {
      const homeLocation = RouteNames.home;
      const splashLocation = RouteNames.splash;

      final isInitialized = _appService.initialized;

      final isGoingToInit = state.matchedLocation == splashLocation;

      // If not Initialized and not going to Initialized redirect to Splash
      if (!isInitialized && !isGoingToInit) {
        return splashLocation;
      } else if (isInitialized && isGoingToInit) {
        return homeLocation;
      }
      return null;
    },
  );
}