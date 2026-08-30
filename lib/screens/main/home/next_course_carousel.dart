import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tattoo/components/notices.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/screens/main/home/next_course_card.dart';

const _pagePadding = 8.0;
const _viewportFraction = 0.88;
const _nextWeekTriggerFraction = 0.5;
const _firstCoursePageIndex = 1;
const _previousWeekRevealDelay = Duration(milliseconds: 300);

enum _WeekDirection { previous, next }

class NextCourseCarousel extends StatefulWidget {
  const NextCourseCarousel({
    super.key,
    required this.courses,
    required this.initialCourseIndex,
    this.onPreviousDate,
    this.onNextDate,
    this.onCourseTap,
  }) : assert(
         initialCourseIndex == null ||
             (initialCourseIndex >= 0 && initialCourseIndex < courses.length),
       );

  final List<NextCourse> courses;
  final int? initialCourseIndex;
  final VoidCallback? onPreviousDate;
  final VoidCallback? onNextDate;
  final ValueChanged<NextCourse>? onCourseTap;

  @override
  State<NextCourseCarousel> createState() => _NextCourseCarouselState();
}

class _NextCourseCarouselState extends State<NextCourseCarousel>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _weekTransitionController;
  late final Animation<Offset> _weekSlideFromLeftAnimation;
  late final Animation<Offset> _weekSlideFromRightAnimation;
  late int _currentIndex;
  var _isSwitchingWeek = false;
  _WeekDirection _weekDirection = .next;

  @override
  void initState() {
    super.initState();
    _currentIndex = _initialPageIndex(widget);
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: _viewportFraction,
    );
    _weekTransitionController = AnimationController(
      value: 1,
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _weekSlideFromLeftAnimation =
        Tween(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            )
            .chain(CurveTween(curve: Curves.easeOutCubic))
            .animate(
              _weekTransitionController,
            );
    _weekSlideFromRightAnimation =
        Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            )
            .chain(CurveTween(curve: Curves.easeOutCubic))
            .animate(
              _weekTransitionController,
            );
  }

  @override
  void didUpdateWidget(NextCourseCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPage = _initialPageIndex(oldWidget);
    final newPage = _initialPageIndex(widget);
    if (oldPage == newPage || _isSwitchingWeek) return;

    _currentIndex = newPage;
    if (_pageController.hasClients) {
      unawaited(
        _pageController.animateToPage(
          newPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        ),
      );
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(newPage);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _weekTransitionController.dispose();
    super.dispose();
  }

  double get _page => _pageController.hasClients
      ? _pageController.page ?? _currentIndex.toDouble()
      : _currentIndex.toDouble();

  double get _terminalProgress =>
      (_page - widget.courses.length).clamp(0.0, 1.0);

  double get _nextWeekProgress =>
      ((_page - (widget.courses.length + 1)) / _nextWeekTriggerFraction).clamp(
        0.0,
        1.0,
      );

  double get _previousWeekProgress =>
      (_firstCoursePageIndex - _page).clamp(0.0, 1.0);

  int get _terminalPageIndex => widget.courses.length + _firstCoursePageIndex;

  int get _nextWeekPageIndex => _terminalPageIndex + 1;

  int get _pageCount => _nextWeekPageIndex + 1;

  bool get _isShowingPreviousDay =>
      _previousWeekProgress > 0 ||
      (_isSwitchingWeek && _weekDirection == .previous);

  bool get _isShowingCourseEnded =>
      _terminalProgress > 0 || (_isSwitchingWeek && _weekDirection == .next);

  Animation<Offset> get _weekSlideAnimation => switch (_weekDirection) {
    .previous => _weekSlideFromRightAnimation,
    .next => _weekSlideFromLeftAnimation,
  };

  Future<void> _switchWeek(_WeekDirection direction) async {
    if (_isSwitchingWeek) return;

    setState(() {
      _isSwitchingWeek = true;
      _weekDirection = direction;
    });

    if (direction == .previous) {
      await Future<void>.delayed(_previousWeekRevealDelay);
      if (!mounted) return;
    }

    final onDateChanged = switch (direction) {
      .previous => widget.onPreviousDate,
      .next => widget.onNextDate,
    };
    onDateChanged?.call();

    setState(() {
      _currentIndex = _firstCoursePageIndex;
    });
    _pageController.jumpToPage(_firstCoursePageIndex);
    await _weekTransitionController.forward(from: 0);

    if (!mounted) return;
    setState(() => _isSwitchingWeek = false);
  }

  Widget _buildPreviousDayNotice(ColorScheme colorScheme) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _pageController,
        builder: (context, child) => ExcludeSemantics(
          excluding: !_isShowingPreviousDay,
          child: Opacity(
            key: const Key('previous-week-loading-notice'),
            opacity: _isShowingPreviousDay ? 1 : 0,
            child: child,
          ),
        ),
        child: Center(
          child: ClearNoticeVertical(
            icon: const Icon(
              Icons.calendar_month_outlined,
              size: 48,
            ),
            text: TextSpan(text: t.home.previousDay),
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildCourseEndedNotice(ColorScheme colorScheme) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _pageController,
        builder: (context, child) => ExcludeSemantics(
          excluding: _currentIndex != _terminalPageIndex,
          child: Opacity(
            key: const Key('course-ended-notice'),
            opacity: _isShowingCourseEnded ? 1 : 0,
            child: Center(
              child: _buildCourseEndedContent(
                colorScheme,
                showProgress: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseEndedContent(
    ColorScheme colorScheme, {
    required bool showProgress,
  }) {
    return ClearNoticeVertical(
      icon: SizedBox.square(
        dimension: 72,
        child: Stack(
          alignment: .center,
          children: [
            if (showProgress && _nextWeekProgress > 0)
              SizedBox.expand(
                child: CircularProgressIndicator(
                  key: const Key('next-week-progress-indicator'),
                  value: _nextWeekProgress,
                  strokeWidth: 3,
                  strokeCap: .round,
                  color: colorScheme.primary,
                ),
              ),
            const Icon(
              Icons.coffee_outlined,
              size: 40,
            ),
          ],
        ),
      ),
      text: TextSpan(
        text: widget.courses.isEmpty
            ? t.home.noCoursesToday
            : t.home.coursesEnded,
      ),
      color: colorScheme.onSurfaceVariant,
    );
  }

  Widget _buildHeightProbe(ColorScheme colorScheme) => switch (widget.courses) {
    [final first, ...] => NextCourseCard(course: first),
    [] => Padding(
      padding: const .symmetric(vertical: 48),
      child: _buildCourseEndedContent(colorScheme, showProgress: false),
    ),
  };

  bool _handleScrollEnd(ScrollEndNotification notification) {
    if (notification.depth != 0) return false;

    if (_currentIndex == _nextWeekPageIndex) {
      unawaited(_switchWeek(.next));
    } else if (_currentIndex == 0) {
      unawaited(_switchWeek(.previous));
    }
    return false;
  }

  Widget _buildCoursePage(int pageIndex, double edgeOverflow) {
    if (pageIndex == 0 || pageIndex >= _terminalPageIndex) {
      return const SizedBox.expand();
    }

    final courseIndex = pageIndex - _firstCoursePageIndex;
    Widget result = Padding(
      key: ValueKey('course-page-$courseIndex'),
      padding: const .all(_pagePadding),
      child: Align(
        alignment: .topCenter,
        child: NextCourseCard(
          course: widget.courses[courseIndex],
          onTap: switch (widget.onCourseTap) {
            final onCourseTap? => () => onCourseTap(
              widget.courses[courseIndex],
            ),
            null => null,
          },
        ),
      ),
    );

    if (courseIndex == 0) {
      result = AnimatedBuilder(
        animation: _pageController,
        builder: (context, child) => Transform.translate(
          offset: Offset(_previousWeekProgress * edgeOverflow, 0),
          child: child,
        ),
        child: result,
      );
    }

    if (courseIndex == widget.courses.length - 1) {
      result = AnimatedBuilder(
        animation: _pageController,
        builder: (context, child) => Transform.translate(
          offset: Offset(-_terminalProgress * edgeOverflow, 0),
          child: child,
        ),
        child: result,
      );
    }

    return result;
  }

  Widget _buildPageIndicator(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) => Opacity(
        key: const Key('course-page-indicator'),
        opacity: (1 - _terminalProgress - _previousWeekProgress).clamp(
          0.0,
          1.0,
        ),
        child: child,
      ),
      child: Row(
        mainAxisSize: .min,
        spacing: 6,
        children: [
          for (var index = 0; index < widget.courses.length; index++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: index == _currentIndex - _firstCoursePageIndex
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                shape: .circle,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      spacing: 8,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final horizontalProbePadding =
                constraints.maxWidth * (1 - _viewportFraction) / 2 +
                _pagePadding;

            return Stack(
              clipBehavior: .none,
              children: [
                Padding(
                  padding: .symmetric(
                    horizontal: horizontalProbePadding,
                    vertical: _pagePadding,
                  ),
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0,
                        child: _buildHeightProbe(colorScheme),
                      ),
                    ),
                  ),
                ),
                _buildPreviousDayNotice(colorScheme),
                _buildCourseEndedNotice(colorScheme),
                Positioned.fill(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(overscroll: false),
                    child: SlideTransition(
                      key: const Key('week-slide-transition'),
                      position: _weekSlideAnimation,
                      child: NotificationListener<ScrollEndNotification>(
                        onNotification: _handleScrollEnd,
                        child: PageView.builder(
                          controller: _pageController,
                          clipBehavior: .none,
                          itemCount: _pageCount,
                          onPageChanged: (index) {
                            setState(() => _currentIndex = index);
                          },
                          itemBuilder: (context, index) => _buildCoursePage(
                            index,
                            horizontalProbePadding * 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (widget.courses.isNotEmpty) _buildPageIndicator(colorScheme),
      ],
    );
  }
}

int _initialPageIndex(NextCourseCarousel carousel) =>
    switch (carousel.initialCourseIndex) {
      final index? => index + _firstCoursePageIndex,
      null => carousel.courses.length + _firstCoursePageIndex,
    };
