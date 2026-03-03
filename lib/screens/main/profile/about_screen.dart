import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tattoo/components/notices.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/services/github_service.dart';
import 'package:url_launcher/url_launcher.dart';

final packageInfoProvider = FutureProvider.autoDispose<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributorsAsync = ref.watch(contributorsProvider);
    final packageInfoAsync = ref.watch(packageInfoProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.profile.options.about),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  spacing: 16,
                  children: [
                    // App Logo and Version
                    Column(
                      spacing: 8,
                      children: [
                        SvgPicture.asset(
                          'assets/tat_icon.svg',
                          width: 80,
                          height: 80,
                        ),
                        Text(
                          t.general.appTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        packageInfoAsync.when(
                          data: (packageInfo) => Text(
                            '${packageInfo.version} (${packageInfo.buildNumber})',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          loading: () => Text(
                            '... (...)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          error: (error, stackTrace) => Text(
                            '... (...)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Description
                    BackgroundNotice(
                      text: t.about.description,
                      noticeType: NoticeType.info,
                    ),

                    // Links Section
                    Column(
                      spacing: 8,
                      children: [
                        SectionHeader(title: t.about.relatedLinks),
                        OptionEntryTile.icon(
                          icon: Icons.code,
                          title: 'GitHub',
                          description: t.about.viewSource,
                          onTap: () => launchUrl(
                            Uri.parse('https://github.com/NTUT-NPC/tattoo'),
                          ),
                        ),
                        OptionEntryTile.icon(
                          icon: Icons.translate,
                          title: 'Crowdin',
                          description: t.about.helpTranslate,
                          onTap: () => launchUrl(
                            Uri.parse('https://translate.ntut.club'),
                          ),
                        ),
                      ],
                    ),

                    // Contributors Section
                    contributorsAsync.when(
                      data: (contributors) => contributors == null
                          ? const SizedBox.shrink()
                          : Column(
                              spacing: 8,
                              children: [
                                SectionHeader(title: t.about.developers),
                                ...contributors.map(
                                  (contributor) => OptionEntryTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        contributor.avatarUrl,
                                        width: 24,
                                        height: 24,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  color: theme.dividerColor,
                                                  child: const Icon(
                                                    Icons.person,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                      ),
                                    ),
                                    title: contributor.login,
                                    onTap: () => launchUrl(
                                      Uri.parse(contributor.htmlUrl),
                                    ),
                                  ),
                                ),
                                OptionEntryTile.svg(
                                  svgIconAsset: 'assets/npc_logo.svg',
                                  title: t.profile.options.npcClub,
                                  actionIcon:
                                      OptionEntryTileActionIcon.exitToApp,
                                  onTap: () =>
                                      launchUrl(Uri.parse('https://ntut.club')),
                                ),
                              ],
                            ),
                      loading: () => Column(
                        spacing: 8,
                        children: [
                          SectionHeader(title: t.about.developers),
                          Skeletonizer(
                            child: Column(
                              spacing: 8,
                              children: List.generate(
                                3,
                                (index) => const OptionEntryTile.icon(
                                  icon: Icons.person,
                                  title: 'Contributor Name',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      error: (err, stack) => Column(
                        spacing: 8,
                        children: [
                          SectionHeader(title: t.about.developers),
                          OptionEntryTile.svg(
                            svgIconAsset: 'assets/npc_logo.svg',
                            title: t.profile.options.npcClub,
                            onTap: () =>
                                launchUrl(Uri.parse('https://ntut.club')),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Copyright
                    ClearNotice(text: t.about.copyright),
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
