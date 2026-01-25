import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WelcomeIntroductionPage extends StatefulWidget {
  const WelcomeIntroductionPage({super.key, this.onRequestNextPage});

  final VoidCallback? onRequestNextPage;

  @override
  State<WelcomeIntroductionPage> createState() =>
      _WelcomeIntroductionPageState();
}

class _WelcomeIntroductionPageState extends State<WelcomeIntroductionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late ScrollController _scrollController;
  bool _didRequestNextPage = false;

  bool get _isAtBottom {
    if (!_scrollController.hasClients) return false;
    return _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 1;
  }

  // When the user drags upward at the bottom, ask the PageView to advance.
  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _didRequestNextPage = false;
    }

    if (_isAtBottom && !_didRequestNextPage) {
      if (notification is OverscrollNotification &&
          notification.overscroll > 0 &&
          notification.dragDetails != null) {
        _didRequestNextPage = true;
        widget.onRequestNextPage?.call();
      } else if (notification is ScrollUpdateNotification) {
        final double delta = notification.scrollDelta ?? 0;
        if (notification.dragDetails != null && delta > 0) {
          _didRequestNextPage = true;
          widget.onRequestNextPage?.call();
        }
      }
    }

    if (notification is ScrollEndNotification) {
      _didRequestNextPage = false;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: -5,
      end: 5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double footerHeight = 60.0;
    // for responsive design, get screen dimensions
    final double screenHeight = MediaQuery.of(context).size.height;
    // var _screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      spacing: 24,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Spacing from top
                        SizedBox(height: screenHeight * 0.05),

                        // Logo and Title
                        Column(
                          children: [
                            SvgPicture.asset(
                              'assets/tat_icon.svg',
                              height: screenHeight * 0.1,
                            ),
                            const Text(
                              'Project Tattoo 北科生活2',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),

                        // Features List
                        Column(
                          spacing: 12.0,
                          children: const [
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

                        // LOGO and Disclaimer Text
                        Column(
                          spacing: 4.0,
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
                                    height: 1.6,
                                    color: Colors.grey[600],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),

                        const SizedBox(height: footerHeight + 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // footer: Animated Scroll Indicator
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Container(
              height: footerHeight,
              decoration: BoxDecoration(
                // Fade effect background
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
                  stops: const [0, 0.5, 1.0],
                ),
              ),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _animation.value),
                    child: child,
                  );
                },
                child: Column(
                  spacing: 4.0,
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_double_arrow_up,
                      color: Colors.grey[600],
                    ),
                    Text(
                      '向上滑動以繼續',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
