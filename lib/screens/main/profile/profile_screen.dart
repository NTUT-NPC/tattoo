import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/screens/main/profile/profile_card.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final authRepository = ref.read(authRepositoryProvider);
    await authRepository.logout();
    if (context.mounted) context.go(AppRoutes.intro);
  }

  void _showDemoTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('尚未實作')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // settings options for the profile tab
    var options = [
      SectionHeader(title: '帳號設定'),
      OptionEntryTile(
        icon: Icons.password,
        title: '更改密碼',
        onTap: () => _showDemoTap(context),
      ),
      OptionEntryTile(
        icon: Icons.image,
        title: '更改個人圖片',
        onTap: () => _showDemoTap(context),
      ),

      SectionHeader(title: 'TAT'),
      OptionEntryTile(
        icon: Icons.favorite_border_outlined,
        title: '支持我們',
        onTap: () => _showDemoTap(context),
      ),
      OptionEntryTile(
        icon: Icons.info_outline,
        title: '關於 TAT',
        onTap: () => _showDemoTap(context),
      ),
      OptionEntryTile(
        svgIconAsset: "assets/npc_logo.svg",
        title: '北科程式設計研究社',
        onTap: () => _showDemoTap(context),
      ),

      SectionHeader(title: '應用程式設定'),
      OptionEntryTile(
        icon: Icons.settings_outlined,
        title: '偏好設定',
        onTap: () => _showDemoTap(context),
      ),
      OptionEntryTile(
        icon: Icons.logout,
        title: '登出帳號',
        onTap: () => _logout(context, ref),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    ProfileCard(),

                    SizedBox(height: 32),

                    Column(
                      spacing: 8,
                      children: options,
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
