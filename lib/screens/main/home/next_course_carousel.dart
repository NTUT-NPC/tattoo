import 'package:flutter/material.dart';
import 'package:tattoo/screens/main/home/next_course_card.dart';

const _pagePadding = 8.0;
const _viewportFraction = 0.88;

class NextCourseCarousel extends StatefulWidget {
  const NextCourseCarousel({
    super.key,
    required this.courses,
    this.onCourseTap,
  });

  final List<NextCourse> courses;
  final ValueChanged<NextCourse>? onCourseTap;

  @override
  State<NextCourseCarousel> createState() => _NextCourseCarouselState();
}

class _NextCourseCarouselState extends State<NextCourseCarousel> {
  late final PageController _pageController;
  var _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _viewportFraction);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.courses.isEmpty) return const SizedBox.shrink();

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
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalProbePadding,
                    vertical: _pagePadding,
                  ),
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0,
                        child: NextCourseCard(course: widget.courses.first),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: PageView.builder(
                    controller: _pageController,
                    clipBehavior: Clip.none,
                    itemCount: widget.courses.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemBuilder: (context, index) => Padding(
                      padding: const .all(_pagePadding),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: NextCourseCard(
                          course: widget.courses[index],
                          onTap: switch (widget.onCourseTap) {
                            final onCourseTap? => () => onCourseTap(
                              widget.courses[index],
                            ),
                            null => null,
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (widget.courses.length > 1)
          Row(
            mainAxisSize: .min,
            spacing: 6,
            children: [
              for (var index = 0; index < widget.courses.length; index++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == _currentIndex
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    shape: .circle,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
