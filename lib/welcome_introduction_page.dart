import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomeIntroductionPage extends StatelessWidget {
  const WelcomeIntroductionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WelcomeIntroductionLayout();
  }
}

class WelcomeIntroductionLayout extends StatelessWidget {
  const WelcomeIntroductionLayout({
    super.key,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 8.0),
  });

  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final sheetColor = Theme.of(context).colorScheme.surface;

    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: contentPadding.add(
              const EdgeInsets.only(top: 16, bottom: 96),
            ),
            child: const WelcomeIntroductionContent(),
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
                      sheetColor,
                      sheetColor,
                      sheetColor.withAlpha(0),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
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
    );
  }
}

class WelcomeIntroductionContent extends StatelessWidget {
  const WelcomeIntroductionContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 24,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo and Title
        Column(
          spacing: 12,
          children: [
            SvgPicture.asset(
              'assets/tat_icon.svg',
              height: 64,
            ),
            Text(
              'Project Tattoo',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),

        // Features List
        Column(
          spacing: 12,
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

        // Logo and disclaimer Text
        Column(
          spacing: 12,
          children: [
            SvgPicture.asset(
              'assets/npc_horizontal.svg',
              height: 24,
              colorFilter: ColorFilter.mode(
                Colors.grey[600]!,
                BlendMode.srcIn,
              ),
            ),

            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                children: [
                  const TextSpan(text: '由'),
                  TextSpan(
                    text: '北科程式設計研究社',
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        launchUrl(Uri.parse('https://ntut.club'));
                      },
                  ),
                  const TextSpan(text: '開發'),
                  const TextSpan(text: '\n'),
                  const TextSpan(
                    text: '所有資訊僅供參考，請以學校官方系統為準',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
