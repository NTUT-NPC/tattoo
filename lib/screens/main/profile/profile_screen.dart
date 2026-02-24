import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/components/notices.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/screens/main/profile/profile_card.dart';
import 'package:tattoo/screens/main/profile/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await ref.read(authRepositoryProvider).getUser(refresh: true);
    await Future.wait([
      ref.refresh(userProfileProvider.future),
      ref.refresh(userAvatarProvider.future),
      ref.refresh(activeRegistrationProvider.future),
    ]);
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final authRepository = ref.read(authRepositoryProvider);
    await authRepository.logout();
    if (context.mounted) context.go(AppRoutes.intro);
  }

  void _showDemoTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.general.notImplemented)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // settings options for the profile tab
    final options = [
      SectionHeader(title: t.profile.sections.accountSettings),
      OptionEntryTile(
        icon: Icons.password,
        title: t.profile.options.changePassword,
        onTap: () => _showDemoTap(context),
      ),
      OptionEntryTile(
        icon: Icons.image,
        title: t.profile.options.changeAvatar,
        onTap: () => _showDemoTap(context),
      ),

      SectionHeader(title: 'TAT'),
      OptionEntryTile(
        icon: Icons.favorite_border_outlined,
        title: t.profile.options.supportUs,
        onTap: () => _showDemoTap(context),
      ),
      OptionEntryTile(
        icon: Icons.info_outline,
        title: t.profile.options.about,
        onTap: () => _showDemoTap(context),
      ),
      OptionEntryTile(
        svgIconAsset: "assets/npc_logo.svg",
        title: t.profile.options.npcClub,
        onTap: () => _showDemoTap(context),
      ),

      SectionHeader(title: t.profile.sections.appSettings),
      OptionEntryTile(
        icon: Icons.settings_outlined,
        title: t.profile.options.preferences,
        onTap: () => _showDemoTap(context),
      ),
      OptionEntryTile(
        icon: Icons.logout,
        title: t.profile.options.logout,
        onTap: () => _logout(context, ref),
      ),
    ];

    final notices = [
      // TODO: make notices dynamic and animated.
      SectionHeader(title: t.profile.sections.notices),

      BackgroundNotice(
        text: t.profile.notices.betaTesting,
        noticeType: NoticeType.info,
      ),

      BackgroundNotice(
        text: t.profile.notices.passwordExpiring,
        noticeType: NoticeType.warning,
      ),

      BackgroundNotice(
        text: t.profile.notices.connectionError,
        noticeType: NoticeType.error,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    spacing: 16,
                    children: [
                      ProfileCard(),

                      ClearNotice(
                        text: t.profile.dataDisclaimer,
                      ),

                      Column(
                        spacing: 8,
                        children: notices,
                      ),

                      Column(
                        spacing: 8,
                        children: options,
                      ),

                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) => ClearNotice(
                          text: snapshot.hasData
                              ? "TAT ${snapshot.data!.version} (${snapshot.data!.buildNumber})"
                              : "TAT",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
