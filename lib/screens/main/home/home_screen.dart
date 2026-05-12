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
    final options = [
      OptionEntryTile.svg(
        svgIconAsset: "assets/tat_icon.svg",
        actionIcon: .exitToApp,
        title: t.home.projectTattoo.title,
        description: t.home.projectTattoo.description,
        onTap: () => launchUrl(.parse(t.home.projectTattoo.url)),
      ),
      OptionEntryTile.icon(
        icon: Icons.explore_outlined,
        actionIcon: .exitToApp,
        title: t.home.ideation.title,
        description: t.home.ideation.description,
        onTap: () => launchUrl(
          .parse(t.home.ideation.url),
        ),
      ),
      OptionEntryTile.svg(
        svgIconAsset: "assets/npc_logo.svg",
        actionIcon: .exitToApp,
        title: t.home.npcClub.title,
        description: t.home.npcClub.description,
        onTap: () => launchUrl(.parse(t.home.npcClub.url)),
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
      OptionEntryTile.icon(
        icon: Icons.how_to_vote_outlined,
        title: t.nav.vote,
        onTap: () => context.push(AppRoutes.kioskLoginQr),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(t.nav.home)),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const .all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                spacing: 8,
                children: options,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
