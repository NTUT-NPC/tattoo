import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
import 'package:tattoo/screens/main/profile/profile_providers.dart';
import 'package:tattoo/services/github_service.dart';
import 'package:tattoo/utils/launch_url.dart';

final packageInfoProvider = FutureProvider.autoDispose<String>((ref) async {
  final packageInfo = await PackageInfo.fromPlatform();
  const suffix = String.fromEnvironment('VERSION_SUFFIX');

  if (suffix.isEmpty) {
    return '${packageInfo.version} (${packageInfo.buildNumber})';
  }
  return '${packageInfo.version}-$suffix (${packageInfo.buildNumber})';
});

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  int _logoClickCount = 0;

  Future<void> _onLogoTap(BuildContext context, WidgetRef ref) async {
    _logoClickCount++;
    if (_logoClickCount != 7) return;

    _logoClickCount = 0;
    final prefs = ref.read(preferencesRepositoryProvider);
    final current = await prefs.get(PrefKey.showDangerZone);
    final newState = !current;
    await prefs.set(PrefKey.showDangerZone, newState);

    ref.invalidate(dangerZoneActionProvider);

    final action = ref.read(dangerZoneActionProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newState
                ? t.profile.dangerZone.goAction(action: action)
                : t.profile.dangerZone.alreadyFull,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        GestureDetector(
                          onTap: () => _onLogoTap(context, ref),
                          child: SvgPicture.asset(
                            'assets/tat_icon.svg',
                            width: 80,
                            height: 80,
                          ),
                        ),
                        Text(
                          t.general.appTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          packageInfoAsync.value ?? '... (...)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        t.about.description,
                        textAlign: .justify,
                      ),
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
                        OptionEntryTile.icon(
                          icon: Icons.privacy_tip,
                          title: t.about.privacyPolicy,
                          description: t.about.viewPrivacyPolicy,
                          onTap: () => launchUrl(
                            Uri.parse(t.about.privacyPolicyUrl),
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
                    Text.rich(
                      TextSpan(text: t.about.copyright),
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.6,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
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
