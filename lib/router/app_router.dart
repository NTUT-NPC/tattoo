import 'package:go_router/go_router.dart';
import 'package:tattoo/router/animated_shell_container.dart';
import 'package:tattoo/screens/main/home_screen.dart';
import 'package:tattoo/screens/main/profile_tab.dart';
import 'package:tattoo/screens/main/score_tab.dart';
import 'package:tattoo/screens/main/table_tab.dart';
import 'package:tattoo/screens/welcome/intro_screen.dart';
import 'package:tattoo/screens/welcome/login_screen.dart';

abstract class AppRoutes {
  static const home = '/';
  static const score = '/score';
  static const profile = '/profile';
  static const intro = '/intro';
  static const login = '/login';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
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
                  const NoTransitionPage(child: TableTab()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.score,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ScoreTab()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ProfileTab()),
            ),
          ],
        ),
      ],
    ),
  ],
);
