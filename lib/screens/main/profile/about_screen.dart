import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tattoo/components/notices.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/contributor.dart';
import 'package:tattoo/services/github_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributorsAsync = ref.watch(contributorsProvider);

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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        FutureBuilder<PackageInfo>(
                          future: PackageInfo.fromPlatform(),
                          builder: (context, snapshot) {
                            final version = snapshot.data?.version ?? '...';
                            final buildNumber =
                                snapshot.data?.buildNumber ?? '...';
                            return Text(
                              'Version $version ($buildNumber)',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                            );
                          },
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
                        SectionHeader(title: t.$wip('相關連結')),
                        OptionEntryTile(
                          icon: Icons.code,
                          title: 'GitHub',
                          description: 'View source code and contribute',
                          onTap: () => launchUrl(
                            Uri.parse('https://github.com/NTUT-NPC/tattoo'),
                          ),
                        ),
                        OptionEntryTile(
                          icon: Icons.translate,
                          title: 'Crowdin',
                          description: 'Help us translate Tattoo',
                          onTap: () => launchUrl(
                            Uri.parse('https://translate.ntut.club'),
                          ),
                        ),
                      ],
                    ),

                    // Contributors Section
                    Column(
                      spacing: 8,
                      children: [
                        SectionHeader(title: t.about.developers),
                        contributorsAsync.when(
                          data: (List<Contributor> contributors) => Column(
                            spacing: 8,
                            children: [
                              ...contributors.map(
                                (Contributor contributor) => OptionEntryTile(
                                  customLeading: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      contributor.avatarUrl,
                                      width: 24,
                                      height: 24,
                                    ),
                                  ),
                                  title: contributor.login,
                                  onTap: () =>
                                      launchUrl(Uri.parse(contributor.htmlUrl)),
                                ),
                              ),
                              OptionEntryTile(
                                svgIconAsset: 'assets/npc_logo.svg',
                                title: t.profile.options.npcClub,
                                actionIcon: OptionEntryTileActionIcon.exitToApp,
                                onTap: () =>
                                    launchUrl(Uri.parse('https://ntut.club')),
                              ),
                            ],
                          ),
                          loading: () => Skeletonizer(
                            child: Column(
                              spacing: 8,
                              children: List.generate(
                                3,
                                (index) => const OptionEntryTile(
                                  icon: Icons.person,
                                  title: 'Contributor Name',
                                ),
                              ),
                            ),
                          ),
                          error: (err, stack) => OptionEntryTile(
                            svgIconAsset: 'assets/npc_logo.svg',
                            title: t.profile.options.npcClub,
                            onTap: () =>
                                launchUrl(Uri.parse('https://ntut.club')),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Copyright
                    ClearNotice(
                      text:
                          'Copyright © 2026 NTUT Programming Club\nLicensed under GPLv3',
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
