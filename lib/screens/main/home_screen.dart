import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/router/app_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authRepository = ref.read(authRepositoryProvider);
    final user = await authRepository.tryAutoLogin();

    if (!mounted) return;

    if (user == null) {
      context.go(AppRoutes.intro);
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    final authRepository = ref.read(authRepositoryProvider);
    await authRepository.logout();
    if (mounted) context.go(AppRoutes.intro);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            Text('Home'),
            ElevatedButton(onPressed: _logout, child: Text('Logout')),
          ],
        ),
      ),
    );
  }
}
