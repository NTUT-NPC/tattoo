import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/router/screen_tracking.dart';

void main() {
  testWidgets('tracks initial tabs, retained revisits, and push/pop returns', (
    tester,
  ) async {
    final screens = <String>[];
    late StatefulNavigationShell shell;
    final router = GoRouter(
      initialLocation: '/course-table',
      routes: [
        GoRoute(
          path: '/portal',
          builder: (_, _) => const Scaffold(body: Text('Portal')),
        ),
        StatefulShellRoute.indexedStack(
          builder: (_, _, navigationShell) {
            shell = navigationShell;
            return navigationShell;
          },
          branches: [
            for (final path in ['/', '/course-table', '/score', '/profile'])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: path,
                    pageBuilder: (_, _) => NoTransitionPage(
                      child: Scaffold(body: Text(path)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    trackScreenViews(router, onScreenView: screens.add);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('/course-table'), findsOneWidget);

    for (final index in [2, 3, 0, 1]) {
      shell.goBranch(index);
      await tester.pumpAndSettle();
    }
    expect(find.text('/course-table'), findsOneWidget);

    unawaited(router.push<void>('/portal'));
    await tester.pumpAndSettle();
    expect(find.text('Portal'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('/course-table'), findsOneWidget);

    router.refresh();
    await tester.pumpAndSettle();
    expect(screens, [
      '/course-table',
      '/score',
      '/profile',
      '/',
      '/course-table',
      '/portal',
      '/course-table',
    ]);
  });

  testWidgets(
    'tracks redirect targets and omits URL values and same-screen updates',
    (
      tester,
    ) async {
      final screens = <String>[];
      final router = GoRouter(
        initialLocation: '/private',
        redirect: (_, state) => state.uri.path == '/private' ? '/login' : null,
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/private', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/login', builder: (_, _) => const Text('Login')),
          GoRoute(
            path: '/details/:id',
            builder: (_, state) =>
                Text('Details ${state.pathParameters['id']}'),
          ),
        ],
      );
      addTearDown(router.dispose);
      trackScreenViews(router, onScreenView: screens.add);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('Login'), findsOneWidget);

      router.go('/details/123?room=A1T101');
      await tester.pumpAndSettle();
      expect(find.text('Details 123'), findsOneWidget);
      router.go('/details/456?room=A2T202');
      await tester.pumpAndSettle();
      expect(find.text('Details 456'), findsOneWidget);
      router.refresh();
      await tester.pumpAndSettle();

      router.go('/login');
      await tester.pumpAndSettle();
      expect(screens, ['/login', '/details/:id', '/login']);
    },
  );
}
