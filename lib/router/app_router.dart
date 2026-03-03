import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/router/animated_shell_container.dart';
import 'package:tattoo/screens/main/home_screen.dart';
import 'package:tattoo/screens/main/profile/profile_screen.dart';
import 'package:tattoo/screens/main/score/score_screen.dart';
import 'package:tattoo/screens/main/course_table/course_table_screen.dart';
import 'package:tattoo/screens/welcome/intro_screen.dart';
import 'package:tattoo/screens/welcome/login_screen.dart';
import 'package:tattoo/services/firebase_service.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

abstract class AppRoutes {
  static const home = '/';
  static const score = '/score';
  static const profile = '/profile';
  static const intro = '/intro';
  static const login = '/login';
}

/// Creates a configured `GoRouter` instance using the provided
/// [firebase] service for analytics and crash reporting observers.
///
/// The global [rootNavigatorKey] and [AppRoutes] constants remain exported
/// so that callers can still refer to them when invoking navigation from
/// outside of a `BuildContext`.
GoRouter createAppRouter(FirebaseService firebase) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    observers: [
      if (firebase.analyticsObserver case final observer?) observer,
    ],
    routes: [
      GoRoute(
        path: AppRoutes.intro,
        builder: (context, state) => const IntroScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            HomeScreen(navigationShell: navigationShell),
        navigatorContainerBuilder: (context, navigationShell, children) {
          return AnimatedShellContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: CourseTableScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.score,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ScoreScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
