import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/screens/main/table_tab.dart';
import 'package:tattoo/screens/main/profile_tab.dart';
import 'package:tattoo/screens/main/score_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isCheckingAuth = true;
  var _currentTabIndex = 0;

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
    } else {
      setState(() => _isCheckingAuth = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) =>
            FadeThroughTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            ),
        child: KeyedSubtree(
          key: ValueKey(_currentTabIndex),
          child: [
            TableTab(),
            ScoreTab(),
            ProfileTab(isLoading: _isCheckingAuth),
          ][_currentTabIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.dashboard), label: '課表'),
          NavigationDestination(icon: Icon(Icons.school), label: '成績'),
          NavigationDestination(icon: Icon(Icons.account_circle), label: '我'),
        ],
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }
}
