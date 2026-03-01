import 'dart:math';

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
import 'package:tattoo/repositories/preferences_repository.dart';
import 'package:tattoo/services/github_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  int _logoClickCount = 0;

  @override
  Widget build(BuildContext context) {
    final testerAction = [
      '點 0 杯啤酒',
      '點 999999999 杯啤酒',
      '點 1 支蜥蜴',
      '點 -1 杯啤酒',
      '點 1 份 asdfghjkl',
      '點 1 碗炒飯',
      '跑進吧檯被店員拖出去',
    ][Random().nextInt(7)];

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
                        GestureDetector(
                          onTap: () async {
                            _logoClickCount++;
                            if (_logoClickCount == 7) {
                              _logoClickCount = 0;
                              await ref
                                  .read(isBarEnabledProvider.notifier)
                                  .toggle();

                              final newState =
                                  ref
                                      .read(isBarEnabledProvider)
                                      .asData
                                      ?.value ??
                                  false;

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      newState ? '去酒吧$testerAction' : '已經吃飽了',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          child: SvgPicture.asset(
                            'assets/tat_icon.svg',
                            width: 80,
                            height: 80,
                          ),
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
                          description: t.about.viewSource,
                          onTap: () => launchUrl(
                            Uri.parse('https://github.com/NTUT-NPC/tattoo'),
                          ),
                        ),
                        OptionEntryTile(
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
