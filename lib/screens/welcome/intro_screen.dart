import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/components/notices.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/shells/showcase_shell.dart';
import 'package:tattoo/utils/env.dart';

class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final verticalPadding = screenHeight * 0.1;

    final title = t.general.appTitle;

    final icon = SvgPicture.asset(
      'assets/tat_icon.svg',
      height: verticalPadding,
    );

    final body = Column(
      spacing: 8,
      children: [
        _FeatureCard(
          title: t.intro.features.courseTable.title,
          description: t.intro.features.courseTable.description,
          icon: Icons.calendar_month,
        ),
        _FeatureCard(
          title: t.intro.features.scores.title,
          description: t.intro.features.scores.description,
          icon: Icons.bar_chart,
        ),
        _FeatureCard(
          title: t.intro.features.campusLife.title,
          description: t.intro.features.campusLife.description,
          icon: Icons.location_city,
        ),
      ],
    );

    final footer = ClearNoticeVertical(
      icon: SvgPicture.asset(
        'assets/npc_horizontal.svg',
        height: 24,
        colorFilter: ColorFilter.mode(
          Colors.grey[600]!,
          BlendMode.srcIn,
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
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 16),
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: FilledButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () async {
                                if (isDemo) {
                                  setState(() => _isLoading = true);
                                  try {
                                    await ref
                                        .read(authRepositoryProvider)
                                        .login(demoUsername, demoPassword);
                                    if (mounted) context.go(AppRoutes.home);
                                  } catch (_) {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                } else {
                                  context.push(AppRoutes.login);
                                }
                              },
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                    strokeCap: StrokeCap.round,
                                  ),
                                )
                                : Text(t.intro.kContinue),
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

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 24,
          children: [
            Icon(icon, size: 28),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
