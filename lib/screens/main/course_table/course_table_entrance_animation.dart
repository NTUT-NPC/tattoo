import 'package:material_ui/material_ui.dart';

/// Shared fade-and-slide entrance animation for course-table entries.
class CourseTableEntranceAnimation extends StatelessWidget {
  const CourseTableEntranceAnimation({
    super.key,
    required this.child,
    required this.delay,
    this.beginOffset = const Offset(0, 16),
    this.timeline,
    this.shouldAnimate,
  });

  static const animationDuration = Duration(milliseconds: 350);

  final Widget child;
  final Duration delay;
  final Offset beginOffset;

  /// Optional page-owned timeline shared by every entry in one view.
  ///
  /// When provided, entries created lazily after the timeline completes render
  /// directly in their final state instead of starting a new animation.
  final AnimationController? timeline;

  /// Evaluated when this entry is mounted, allowing lazily-created entries to
  /// skip an entrance animation after their parent view's first frame.
  final ValueGetter<bool>? shouldAnimate;

  @override
  Widget build(BuildContext context) {
    if (shouldAnimate case final shouldAnimate? when !shouldAnimate()) {
      return child;
    }

    final totalDuration = animationDuration + delay;
    final startAt = delay.inMicroseconds / totalDuration.inMicroseconds;

    if (timeline case final timeline?) {
      final timelineDuration = timeline.duration!;
      final timelineStartAt =
          delay.inMicroseconds / timelineDuration.inMicroseconds;
      final timelineEndAt =
          totalDuration.inMicroseconds / timelineDuration.inMicroseconds;
      final curve = Interval(
        timelineStartAt,
        timelineEndAt,
        curve: Curves.easeOutCubic,
      );

      return AnimatedBuilder(
        animation: timeline,
        builder: (context, child) => _buildTransition(
          progress: curve.transform(timeline.value),
          child: child,
        ),
        child: child,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: totalDuration,
      curve: Interval(startAt, 1, curve: Curves.easeOutCubic),
      builder: (context, progress, child) => _buildTransition(
        progress: progress,
        child: child,
      ),
      child: child,
    );
  }

  Widget _buildTransition({
    required double progress,
    required Widget? child,
  }) {
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: beginOffset * (1 - progress),
        child: child,
      ),
    );
  }
}
