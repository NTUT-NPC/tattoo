import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/utils/launch_url.dart';

class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.nav.home)),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const .all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                spacing: 8,
                children: [
                  OptionEntryTile.svg(
                    svgIconAsset: "assets/tat_icon.svg",
                    actionIcon: .exitToApp,
                    title: '關於 Project Tattoo',
                    description: '查看更多資訊或邀請你的朋友加入測試計畫。',
                    onTap: () => launchUrl(.parse('https://ntut.app')),
                  ),
                  OptionEntryTile.icon(
                    icon: Icons.explore_outlined,
                    actionIcon: .exitToApp,
                    title: '屬於我們的 TAT 正在打造中',
                    description: '我們正在募集關於「首頁」的想法，歡迎把你的提案分享給我們！',
                    onTap: () => launchUrl(
                      .parse(
                        'https://forms.gle/LdQdMfvAfUYyGE4k8',
                      ),
                    ),
                  ),
                  OptionEntryTile.svg(
                    svgIconAsset: "assets/npc_logo.svg",
                    actionIcon: .exitToApp,
                    title: t.profile.options.npcClub,
                    description: "有任何想法或是想加入開發，隨時歡迎聯絡我們！",
                    onTap: () => launchUrl(.parse('https://ntut.club')),
                  ),
                  OptionEntryTile.icon(
                    icon: Icons.qr_code_scanner,
                    title: t.scanner.loginIStudy,
                    onTap: () => context.push(AppRoutes.scanner),
                  ),
                  OptionEntryTile.icon(
                    icon: Icons.switch_access_shortcut_outlined,
                    title: t.nav.portal,
                    onTap: () => context.push(AppRoutes.portal),
                  ),
                  OptionEntryTile.icon(
                    icon: Icons.calendar_month,
                    title: t.nav.calendar,
                    onTap: () => context.push(AppRoutes.calendar),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
