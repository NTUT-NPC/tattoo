import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/components/feature_card.dart';
import 'package:tattoo/components/notices.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/services/update_service.dart';
import 'package:tattoo/shells/showcase_shell.dart';
import 'package:tattoo/utils/auto_spacing.dart';

class WhatsNewScreen extends StatefulWidget {
  const WhatsNewScreen({super.key});

  @override
  State<WhatsNewScreen> createState() => _WhatsNewScreenState();
}

class _WhatsNewScreenState extends State<WhatsNewScreen> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final version = await getCurrentSemVer();
    if (mounted) setState(() => _version = version);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = t.whatsNew.title;

    final icon = SvgPicture.asset(
      'assets/tat_icon.svg',
      colorFilter: switch (theme.brightness) {
        .dark => .mode(
          theme.colorScheme.onSurfaceVariant,
          .srcIn,
        ),
        .light => null,
      },
    );

    final body = Column(
      spacing: 8,
      children: [
        for (final feature in currentWhatsNewFeatures())
          FeatureCard(
            icon: feature.icon,
            title: feature.title.spaced,
            description: feature.description.spaced,
          ),
      ],
    );

    final footer = ClearNoticeVertical(
      icon: SvgPicture.asset(
        'assets/npc_horizontal.svg',
        height: 24,
        colorFilter: .mode(
          theme.colorScheme.onSurfaceVariant,
          .srcIn,
        ),
      ),
      text: TextSpan(text: t.intro.developedBy),
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ShowcaseShell(
              icon: icon,
              title: title,
              subtitle: _version,
              body: body,
              footer: footer,
            ),

            // Bottom button with gradient fade
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  width: .infinity,
                  padding: const .only(top: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        theme.scaffoldBackgroundColor,
                        theme.scaffoldBackgroundColor,
                        theme.scaffoldBackgroundColor.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: Padding(
                    padding: const .fromLTRB(16, 8, 16, 0),
                    child: FilledButton(
                      onPressed: () => context.pop(),
                      child: Padding(
                        padding: const .all(6.0),
                        child: Text(t.whatsNew.gotIt),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A feature in the current release; null platforms means all platforms.
class WhatsNewFeature {
  const WhatsNewFeature({
    required this.icon,
    required this.title,
    required this.description,
    this.availablePlatforms,
  });

  final IconData icon;
  final String title;
  final String description;
  final Set<TargetPlatform>? availablePlatforms;
}

/// The current release's features, filtered for the running platform.
/// Update this list before each release; no historical releases are retained.
List<WhatsNewFeature> currentWhatsNewFeatures() =>
    [
          WhatsNewFeature(
            icon: Icons.widgets_outlined,
            title: t.newFeatures.androidWidget.title,
            description: t.newFeatures.androidWidget.description,
            availablePlatforms: const {.android},
          ),
          WhatsNewFeature(
            icon: Icons.map_outlined,
            title: t.newFeatures.campusMap.title,
            description: t.newFeatures.campusMap.description,
          ),
          WhatsNewFeature(
            icon: Icons.download_outlined,
            title: t.newFeatures.materialDownload.title,
            description: t.newFeatures.materialDownload.description,
          ),
          WhatsNewFeature(
            icon: Icons.groups_outlined,
            title: t.newFeatures.ntutSu.title,
            description: t.newFeatures.ntutSu.description,
          ),
        ]
        .where(
          (feature) =>
              feature.availablePlatforms?.contains(defaultTargetPlatform) ??
              true,
        )
        .toList();
