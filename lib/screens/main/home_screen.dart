import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/i18n/strings.g.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
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
            icon: Icon(Icons.account_circle),
            label: t.nav.profile,
          ),
        ],
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }
}
