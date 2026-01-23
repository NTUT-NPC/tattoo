import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tattoo/main.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),

          child: Column(
            spacing: 24,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(),

              // Logo and Title
              Column(
                children: [
                  SvgPicture.asset('assets/tat_icon.svg', height: 96),
                  const Text(
                    'Project Tattoo 北科生活2',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              // Features List
              Column(
                spacing: 12.0,
                children: [
                  const _FeatureCard(
                    title: '查課表',
                    description: '快速查看課表和課程資訊，並可快速切換學期。',
                    icon: Icons.calendar_month,
                  ),
                  const _FeatureCard(
                    title: '看成績',
                    description: '即時查詢各科成績與學分，整合歷年成績紀錄。',
                    icon: Icons.bar_chart,
                  ),
                  const _FeatureCard(
                    title: '北科生活',
                    description: '彙整其他校園生活資訊，更多功能敬請期待。',
                    icon: Icons.location_city,
                  ),
                ],
              ),

              Spacer(),

              // LOGO and Disclaimer Text
              Column(
                spacing: 4.0,
                children: [
                  SvgPicture.asset(
                    'assets/NPC_horizontal.svg',
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      Colors.grey[600]!,
                      BlendMode.srcIn,
                    ),
                  ),
                  Text(
                    '由北科程式設計研究社開發\n所有資訊僅供參考，請以學校官方系統為準',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.6,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _controller.value * 10 - 5),
                    child: child,
                  );
                },
                child: SizedBox(
                  child: Column(
                    spacing: 8.0,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_double_arrow_up,
                        color: Colors.grey[600],
                      ),

                      Text(
                        '向上滑動以繼續',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 8.0),
              // // Get Started Button
              // Padding(
              //   padding: const EdgeInsets.only(bottom: 32.0),
              //   child: SizedBox(
              //     width: 200,
              //     height: 64,
              //     child: FilledButton(
              //       onPressed: () {
              //         Navigator.of(context).pushReplacement(
              //           MaterialPageRoute(builder: (_) => const MyHomePage()),
              //         );
              //       },
              //       child: const Text('開始使用'),
              //     ),
              //   ),
              // ),
            ],
          ),
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
                    Text(description, style: const TextStyle(fontSize: 12)),
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
