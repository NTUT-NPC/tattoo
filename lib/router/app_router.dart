import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/shells/animated_shell_container.dart';
import 'package:tattoo/screens/main/home_screen.dart';
import 'package:tattoo/screens/main/portal/portal_screen.dart';
import 'package:tattoo/screens/main/profile/about_screen.dart';
import 'package:tattoo/screens/main/profile/profile_screen.dart';
import 'package:tattoo/screens/main/score/score_screen.dart';
import 'package:tattoo/screens/main/course_table/course_table_screen.dart';
import 'package:tattoo/screens/welcome/intro_screen.dart';
import 'package:tattoo/screens/welcome/login_screen.dart';
import 'package:tattoo/screens/main/profile/feature_flag_screen.dart';
import 'package:tattoo/screens/main/scanner/scanner_screen.dart';
import 'package:tattoo/services/firebase_service.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

abstract class AppRoutes {
  static const home = '/';
  static const score = '/score';
  static const portal = '/portal';
  static const profile = '/profile';
  static const intro = '/intro';
  static const login = '/login';
  static const about = '/about';
  static const featureFlags = '/feature-flags';
  static const scanner = '/scanner';
}

/// Bridges [sessionProvider] to a [Listenable] for [GoRouter.refreshListenable].
class _SessionRefreshListenable extends ChangeNotifier {
  _SessionRefreshListenable(ProviderContainer container) {
    container.listen(sessionProvider, (_, _) => notifyListeners());
  }
}

/// Routes that don't require authentication.
const _publicRoutes = {AppRoutes.intro, AppRoutes.login, AppRoutes.about};

/// Creates a configured [GoRouter] starting at [initialLocation].
///
/// Watches [sessionProvider] via [refreshListenable] and redirects to
/// [AppRoutes.login] when the session becomes inactive.
GoRouter createAppRouter({
  required String initialLocation,
  required ProviderContainer container,
}) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: initialLocation,
  refreshListenable: _SessionRefreshListenable(container),
  redirect: (context, state) {
    final hasSession = container.read(sessionProvider);
    if (hasSession) return null;
    if (_publicRoutes.contains(state.matchedLocation)) return null;
    return AppRoutes.login;
  },
  observers: [
    ?firebaseService.analyticsObserver,
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
    GoRoute(
      path: AppRoutes.about,
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: AppRoutes.featureFlags,
      builder: (context, state) => const FeatureFlagScreen(),
    ),
    GoRoute(
      path: AppRoutes.scanner,
      builder: (context, state) => const ScannerScreen(),
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
              path: AppRoutes.portal,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: PortalScreen()),
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
