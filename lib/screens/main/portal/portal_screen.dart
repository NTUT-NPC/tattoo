import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/services/portal/portal_service.dart';
import 'package:tattoo/utils/launch_url.dart';

// TODO: Fetch portal services from backend instead of hardcoding.
final _portalServices = <({String title, String serviceCode})>[
  (
    title: '學生查詢系統',
    serviceCode: PortalServiceCode.studentQueryService.code,
  ),
  (
    title: '課程系統',
    serviceCode: PortalServiceCode.courseService.code,
  ),
];

class PortalScreen extends ConsumerWidget {
  const PortalScreen({super.key});

  Future<void> _openNtutService(
    BuildContext context,
    WidgetRef ref,
    String serviceCode,
  ) async {
    try {
      await launchNtutService(
        ref.read(authRepositoryProvider),
        serviceCode,
      );
    } on DioException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(t.errors.connectionFailed)),
        );
    } on ArgumentError {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(t.errors.occurred)),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(t.nav.portal)),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.builder(
                itemCount: _portalServices.isEmpty
                    ? 0
                    : _portalServices.length * 2 - 1,
                itemBuilder: (context, index) {
                  if (index.isOdd) return const SizedBox(height: 16);

                  final service = _portalServices[index ~/ 2];

                  return _PortalCard(
                    title: service.title,
                    onTap: () => _openNtutService(
                      context,
                      ref,
                      service.serviceCode,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortalCard extends StatelessWidget {
  const _PortalCard({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            title,
            textAlign: .start,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: .w600,
            ),
          ),
        ),
      ),
    );
  }
}
