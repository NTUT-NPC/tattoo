import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
import 'package:tattoo/screens/main/calendar/calendar_screen.dart';
import 'package:tattoo/screens/main/course_table/course_table_screen.dart';
import 'package:tattoo/screens/main/home/home_screen.dart';
import 'package:tattoo/screens/main/home_screen.dart';
import 'package:tattoo/screens/main/kiosk_login/kiosk_login_qr_screen.dart';
import 'package:tattoo/screens/main/portal/portal_screen.dart';
import 'package:tattoo/screens/main/profile/about_screen.dart';
import 'package:tattoo/screens/main/profile/ntut_wifi_screen.dart';
import 'package:tattoo/screens/main/profile/preference_detail_screen.dart';
import 'package:tattoo/screens/main/profile/preferences_screen.dart';
import 'package:tattoo/screens/main/profile/profile_screen.dart';
import 'package:tattoo/screens/main/profile/regedit_screen.dart';
import 'package:tattoo/screens/main/scanner/scanner_screen.dart';
import 'package:tattoo/screens/main/score/score_screen.dart';
import 'package:tattoo/screens/update_screen.dart';
import 'package:tattoo/screens/welcome/change_password_screen.dart';
import 'package:tattoo/screens/welcome/intro_screen.dart';
import 'package:tattoo/screens/welcome/login_screen.dart';
import 'package:tattoo/services/firebase_service.dart';
import 'package:tattoo/services/update_service.dart';
import 'package:tattoo/shells/animated_shell_container.dart';
import 'package:tattoo/shells/centered_max_width_frame.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

abstract class AppRoutes {
  static const home = '/';
  static const courseTable = '/course-table';
  static const score = '/score';
  static const portal = '/portal';
  static const calendar = '/calendar';
  static const profile = '/profile';
  static const preferences = '/preferences';
  static const language = '/preferences/language';
  static const themeMode = '/preferences/theme';
  static const intro = '/intro';
  static const login = '/login';
  static const about = '/about';
  static const scanner = '/scanner';
  static const kioskLoginQr = '/kiosk-login-qr';
  static const ntutWifi = '/ntut-8021x';
  static const regedit = '/regedit';
  static const changePassword = '/change-password';
  static const update = '/update';
}

/// Resolves the landing route used after authentication.
///
/// Falls back to home if preferences cannot be read so a storage failure does
/// not block app startup or a successful login.
Future<String> resolveLandingLocation(
  PreferencesRepository preferencesRepository,
) async {
  try {
    final startWithCourseTable = await preferencesRepository.get(
      PrefKey.startWithCourseTable,
    );
    return switch (startWithCourseTable) {
      true => AppRoutes.courseTable,
      false => AppRoutes.home,
    };
  } catch (error) {
    debugPrint('Failed to resolve authenticated landing preference: $error');
    return AppRoutes.home;
  }
}

Widget _framed(Widget child) => CenteredMaxWidthFrame(child: child);

/// Bridges [sessionProvider] to a [Listenable] for [GoRouter.refreshListenable].
class _SessionRefreshListenable extends ChangeNotifier {
  _SessionRefreshListenable(ProviderContainer container) {
    container.listen(sessionProvider, (_, _) => notifyListeners());
  }
}

/// Routes that don't require authentication.
const _publicRoutes = {
  AppRoutes.intro,
  AppRoutes.login,
  AppRoutes.about,
  AppRoutes.changePassword,
  AppRoutes.update,
};

/// Creates a configured [GoRouter] starting at [initialLocation].
///
/// Watches [sessionProvider] via
/// [GoRouter.new]'s `refreshListenable`. Redirects to
/// [AppRoutes.update] when a *forced* update is pending (highest
/// priority), and to [AppRoutes.login] when the session is inactive.
/// Optional updates are surfaced as a dismissible banner instead.
GoRouter createAppRouter({
  required String initialLocation,
  required String landingLocation,
  required ProviderContainer container,
}) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: initialLocation,
  refreshListenable: _SessionRefreshListenable(container),
  redirect: (context, state) {
    // Force-update gate: block all navigation when a forced update is pending.
    final updateConfig = container.read(updateConfigProvider);
    final isForcedUpdate = updateConfig?.isForcedUpdate == true;
    if (isForcedUpdate) {
      if (state.matchedLocation == AppRoutes.update) return null;
      return AppRoutes.update;
    }

    // Escape: forced update cleared remotely while user is on the gate screen.
    // Also kicks the user out if they manually navigated to the update screen
    // but no update is actually available.
    if (state.matchedLocation == AppRoutes.update && updateConfig == null) {
      final hasSession = container.read(sessionProvider);
      return hasSession ? landingLocation : AppRoutes.intro;
    }

    // Auth gate: redirect unauthenticated users to login.
    final hasSession = container.read(sessionProvider);
    if (hasSession) return null;
    if (_publicRoutes.contains(state.matchedLocation)) return null;
    return AppRoutes.login;
  },
  observers: [
    if (firebaseService.analyticsObserver != null)
      firebaseService.analyticsObserver!,
  ],
  routes: [
    GoRoute(
      path: AppRoutes.update,
      builder: (context, state) => const UpdateScreen(),
    ),
    GoRoute(
      path: AppRoutes.intro,
      builder: (context, state) => const IntroScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => _framed(const LoginScreen()),
    ),
    GoRoute(
      path: AppRoutes.changePassword,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final isExpired = extra?['isExpired'] as bool? ?? false;
        final username = extra?['username'] as String?;
        return _framed(
          ChangePasswordScreen(
            isExpired: isExpired,
            username: username,
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.about,
      builder: (context, state) => _framed(const AboutScreen()),
    ),
    GoRoute(
      path: AppRoutes.scanner,
      builder: (context, state) => const ScannerScreen(),
    ),
    GoRoute(
      path: AppRoutes.regedit,
      builder: (context, state) => _framed(const RegeditScreen()),
    ),
    GoRoute(
      path: AppRoutes.preferences,
      builder: (context, state) => _framed(const PreferencesScreen()),
    ),
    GoRoute(
      path: AppRoutes.language,
      builder: (context, state) => _framed(
        const PreferenceDetailScreen(id: .language),
      ),
    ),
    GoRoute(
      path: AppRoutes.themeMode,
      builder: (context, state) => _framed(
        const PreferenceDetailScreen(id: .themeMode),
      ),
    ),
    GoRoute(
      path: AppRoutes.portal,
      builder: (context, state) => _framed(const PortalScreen()),
    ),
    GoRoute(
      path: AppRoutes.calendar,
      builder: (context, state) => _framed(const CalendarScreen()),
    ),
    GoRoute(
      path: AppRoutes.kioskLoginQr,
      builder: (context, state) => _framed(const KioskLoginQrScreen()),
    ),
    GoRoute(
      path: AppRoutes.ntutWifi,
      builder: (context, state) => const NtutWifiScreen(),
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
                  NoTransitionPage(child: _framed(const MainHomeScreen())),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.courseTable,
              pageBuilder: (context, state) =>
                  NoTransitionPage(child: _framed(const CourseTableScreen())),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.score,
              pageBuilder: (context, state) =>
                  NoTransitionPage(child: _framed(const ScoreScreen())),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              pageBuilder: (context, state) =>
                  NoTransitionPage(child: _framed(const ProfileScreen())),
            ),
          ],
        ),
      ],
    ),
  ],
);
