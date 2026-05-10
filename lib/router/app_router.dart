import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/screens/main/home_screen.dart';
import 'package:tattoo/screens/main/profile/about_screen.dart';
import 'package:tattoo/screens/welcome/intro_screen.dart';
import 'package:tattoo/screens/welcome/login_screen.dart';
import 'package:tattoo/services/firebase_service.dart';
import 'package:tattoo/shells/animated_shell_container.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

abstract class AppRoutes {
  static const home = '/';
  static const intro = '/intro';
  static const login = '/login';
  static const about = '/about';
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
      path: AppRoutes.scanner,
      builder: (context, state) => const ScannerScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
