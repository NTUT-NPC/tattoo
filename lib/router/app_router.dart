import 'package:go_router/go_router.dart';
import 'package:tattoo/router/animated_shell_container.dart';
import 'package:tattoo/screens/main/calendar/calendar_screen.dart';
import 'package:tattoo/screens/main/home_screen.dart';
import 'package:tattoo/screens/main/profile/profile_screen.dart';
import 'package:tattoo/screens/main/score/score_screen.dart';
import 'package:tattoo/screens/main/course_table/course_table_screen.dart';
import 'package:tattoo/screens/welcome/intro_screen.dart';
import 'package:tattoo/screens/welcome/login_screen.dart';

abstract class AppRoutes {
  static const home = '/';
  static const score = '/score';
  static const calendar = '/calendar';
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
              path: AppRoutes.calendar,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CalendarScreen()),
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
