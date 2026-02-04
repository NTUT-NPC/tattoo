import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tattoo/screens/welcome/login_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 16), // Fixed bottom padding
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        0,
                        MediaQuery.of(context).size.height * 0.1,
                        0,
                        MediaQuery.of(context).size.height * 0.1 +
                            16, // Extra padding to avoid bottom bar overlap
                      ),
                      child: Column(
                        spacing: 24,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Spacer(flex: 1),
                          // Logo and Title
                          Column(
                            children: [
                              SvgPicture.asset(
                                'assets/tat_icon.svg',
                                height:
                                    MediaQuery.of(context).size.height * 0.1,
                              ),
                              Text(
                                'Project Tattoo',
                                style: Theme.of(context).textTheme.headlineLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),

                          Spacer(flex: 1),
                          // Features List
                          Column(
                            spacing: 8,
                            children: [
                              _FeatureCard(
                                title: '查課表',
                                description: '快速查看課表和課程資訊，並可快速切換學期。',
                                icon: Icons.calendar_month,
                              ),
                              _FeatureCard(
                                title: '看成績',
                                description: '即時查詢各科成績與學分，整合歷年成績紀錄。',
                                icon: Icons.bar_chart,
                              ),
                              _FeatureCard(
                                title: '北科生活',
                                description: '彙整其他校園生活資訊，更多功能敬請期待。',
                                icon: Icons.location_city,
                              ),
                            ],
                          ),

                          Spacer(flex: 2),

                          // Logo and Disclaimer
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
                                '由北科程式設計研究社開發\n所有資訊僅供參考，請以學校官方系統為準',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
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
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: const Text('繼續'),
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
