import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/components/webview_sheet.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/utils/launch_url.dart';

String? scannedAuthCode;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _openVotingSystem(BuildContext context, WidgetRef ref) async {
    if (scannedAuthCode != null) {
      final url = Uri.parse(
        'https://aps-staff.ntut.edu.tw/vote/callback.jsp?oauthServer=http%3A%2F%2Fapp.ntut.edu.tw&code=$scannedAuthCode&redirect_uri=https%3A%2F%2Faps-staff.ntut.edu.tw%2Fvote%2Fcallback.jsp',
      );
      if (context.mounted) {
        WebviewSheet.show(context, url);
      }
      return;
    }

    try {
      await launchNtutService(
        context,
        ref.read(authRepositoryProvider),
        'per_001_oauth',
      );
    } on DioException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(t.errors.connectionFailed)),
        );
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    scannedAuthCode = null;
    await ref.read(authRepositoryProvider).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('首頁')),
      body: SafeArea(
        child: Padding(
          padding: const .all(16),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Expanded(
                child: Card(
                  clipBehavior: .antiAlias,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: .circular(24),
                  ),
                  child: InkWell(
                    onTap: () => _openVotingSystem(context, ref),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: .center,
                        children: [
                          Icon(
                            Icons.how_to_vote,
                            size: 80,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '前往投票系統',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: .bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => _logout(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('登出'),
                style: TextButton.styleFrom(
                  padding: const .symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
