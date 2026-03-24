import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/components/notices.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/utils/launch_url.dart';

// TODO: Fetch portal services from backend instead of hardcoding.
final _portalSections =
    <
      ({
        String title,
        List<({String title, String serviceCode})> services,
      })
    >[
      (
        title: '學務系統',
        services: [
          (
            title: '學生查詢系統',
            serviceCode: 'sa_003_oauth',
          ),
          (
            title: '學生請假系統',
            serviceCode: 'sa_010_oauth',
          ),
          (
            title: '學雜費減免及弱勢助學申請系統',
            serviceCode: 'NTUT_exemption_oauth',
          ),
          (
            title: '就學貸款申請系統',
            serviceCode: 'sa_SLAS_oauth',
          ),
          (
            title: '諮商預約系統',
            serviceCode: 'counseling_oauth',
          ),
        ],
      ),
      (
        title: '教務系統',
        services: [
          (
            title: '課程系統',
            serviceCode: 'aa_0010-oauth',
          ),
          (
            title: '期末網路教學評量系統',
            serviceCode: 'aa_009_oauth',
          ),
          (
            title: '期末網路預選系統',
            serviceCode: 'aa_011_oauth',
          ),
          (
            title: '暑修需求登錄',
            serviceCode: 'aa_015_oauth',
          ),
          (
            title: '期中網路撤選系統（學生）',
            serviceCode: 'aa_Online+Course+Withdrawal+System_stu_oauth',
          ),
        ],
      ),
      (
        title: '總務系統',
        services: [
          (
            title: '建物與設備維修通報單錄案系統',
            serviceCode: 'ga_008_oauth',
          ),
          (
            title: '化學物質GHS管理系統',
            serviceCode: 'ga_ghs_oauth',
          ),
          (
            title: '線上繳費系統',
            serviceCode: 'OnlinePayment_oauth',
          ),
        ],
      ),
      (
        title: '資訊服務',
        services: [
          (
            title: '網路與資訊安全管理系統',
            serviceCode: 'ipmac_oauth',
          ),
          (
            title: '校園授權軟體',
            serviceCode: 'inf001_oauth',
          ),
          (
            title: '電子郵件/網路郵局WebMail',
            serviceCode: 'zimbrasso_oauth',
          ),
          (
            title: '臺北科大小郵差',
            serviceCode: 'test_postman',
          ),
        ],
      ),
      (
        title: '圖書館系統',
        services: [
          (
            title: '圖書館系統',
            serviceCode: 'lib_002_oauth',
          ),
        ],
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
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: .center,
                  spacing: 12,
                  children: [
                    ClearNotice(text: "此功能尚在實驗階段，未讀取可用功能，與實際系統可能有差異"),
                    // TODO: auto-login to nportal
                    _PortalCard(
                      title: "打開校園入口網站",
                      onTap: () => launchUrl(
                        Uri.parse('https://nportal.ntut.edu.tw'),
                      ),
                    ),
                    _PortalCard(
                      title: t.scanner.loginIStudy,
                      onTap: () => context.push(AppRoutes.scanner),
                    ),
                    for (final section in _portalSections)
                      Column(
                        crossAxisAlignment: .center,
                        spacing: 4,
                        children: [
                          SectionHeader(title: section.title),
                          for (final service in section.services)
                            _PortalCard(
                              title: service.title,
                              onTap: () => _openNtutService(
                                context,
                                ref,
                                service.serviceCode,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
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
      clipBehavior: .antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const .symmetric(horizontal: 16, vertical: 12),
            child: Text(
              title,
              textAlign: .start,
              maxLines: 2,
              overflow: .ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}
