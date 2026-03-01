import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/screens/main/profile/profile_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authRepository = ref.read(authRepositoryProvider);
    final hasCredentials = await authRepository.hasCredentials();

    if (!mounted) return;

    if (!hasCredentials) {
      context.go(AppRoutes.intro);
    }
  }

  void _onDestinationSelected(int index) {
    if (index == 2) {
      ref.read(testerActionProvider.notifier).refresh();
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
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
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }
}
