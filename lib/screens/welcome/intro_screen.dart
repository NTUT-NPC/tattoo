import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/router/app_router.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final verticalPadding = screenHeight * 0.1;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 16),
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        0,
                        verticalPadding,
                        0,
                        // Extra padding to avoid bottom bar overlap
                        verticalPadding + 16,
                      ),
                      child: Column(
                        spacing: 24,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Spacer(flex: 1),

                          // Logo and title
                          Column(
                            children: [
                              SvgPicture.asset(
                                'assets/tat_icon.svg',
                                height: verticalPadding,
                              ),
                              Text(
                                t.general.appTitle,
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),

                          Spacer(flex: 1),

                          // Features list
                          Column(
                            spacing: 8,
                            children: [
                              _FeatureCard(
                                title: t.intro.features.courseTable.title,
                                description:
                                    t.intro.features.courseTable.description,
                                icon: Icons.calendar_month,
                              ),
                              _FeatureCard(
                                title: t.intro.features.scores.title,
                                description:
                                    t.intro.features.scores.description,
                                icon: Icons.bar_chart,
                              ),
                              _FeatureCard(
                                title: t.intro.features.campusLife.title,
                                description:
                                    t.intro.features.campusLife.description,
                                icon: Icons.location_city,
                              ),
                            ],
                          ),

                          Spacer(flex: 2),

                          // Logo and disclaimer
                          Column(
                            spacing: 8,
                            children: [
                              SvgPicture.asset(
                                'assets/npc_horizontal.svg',
                                height: 24,
                                colorFilter: ColorFilter.mode(
                                  Colors.grey[600]!,
                                  BlendMode.srcIn,
                                ),
                              ),
                              Text(
                                t.intro.developedBy,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.5,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
                      onPressed: () => context.push(AppRoutes.login),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(t.intro.kContinue),
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
