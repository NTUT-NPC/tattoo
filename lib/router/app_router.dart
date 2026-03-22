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
}

/// Bridges [authStatusProvider] to a [Listenable] for [GoRouter.refreshListenable].
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(ProviderContainer container) {
    container.listen(authStatusProvider, (_, _) => notifyListeners());
  }
}

/// Routes that don't require authentication.
const _publicRoutes = {AppRoutes.intro, AppRoutes.login, AppRoutes.about};

/// Creates a configured [GoRouter] starting at [initialLocation].
///
/// Watches [authStatusProvider] via [refreshListenable] and redirects to
/// [AppRoutes.login] when auth status becomes [AuthStatus.unauthenticated].
GoRouter createAppRouter({
  required String initialLocation,
  required ProviderContainer container,
}) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: initialLocation,
  refreshListenable: _AuthRefreshListenable(container),
  redirect: (context, state) {
    final authStatus = container.read(authStatusProvider);
    if (authStatus != .unauthenticated) return null;
    if (_publicRoutes.contains(state.matchedLocation)) return null;
    return AppRoutes.login;
  },
  observers: [
    if (firebaseService.analyticsObserver case final observer?) observer,
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
