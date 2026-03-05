import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/screens/main/profile/profile_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(WidgetRef ref, int index) {
    final route = navigationShell.route.branches[index].defaultRoute?.path;
    if (route == AppRoutes.profile) {
      ref.invalidate(dangerZoneActionProvider);
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: t.nav.courseTable,
          ),
          NavigationDestination(icon: Icon(Icons.school), label: t.nav.scores),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: t.nav.calendar,
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle),
            label: t.nav.profile,
          ),
        ],
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _onDestinationSelected(ref, index),
      ),
    );
  }
}
