import 'package:flutter/material.dart';

/// Shared fade-and-slide entrance animation for course-table entries.
class CourseTableEntranceAnimation extends StatelessWidget {
  const CourseTableEntranceAnimation({
    super.key,
    required this.child,
    required this.delay,
    this.beginOffset = const Offset(0, 16),
  });

  static const animationDuration = Duration(milliseconds: 350);

  final Widget child;
  final Duration delay;
  final Offset beginOffset;

  @override
  Widget build(BuildContext context) {
    final totalDuration = animationDuration + delay;
    final startAt = delay.inMicroseconds / totalDuration.inMicroseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: totalDuration,
      curve: Interval(startAt, 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) {
        return Opacity(
          opacity: 1 - t,
          child: Transform.translate(
            offset: beginOffset * t,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
