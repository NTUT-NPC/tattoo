import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

/// A branch container that animates index changes with a fade-through effect.
///
/// Each branch stays mounted in the tree, so widget state is preserved while
/// switching tabs. During transition, only the current and previous branches
/// are visible, and only the current branch receives pointer events.
///
/// Example:
/// ```dart
/// AnimatedShellContainer(
///   currentIndex: navigationShell.currentIndex,
///   children: navigationShell.branchNavigators,
/// )
/// ```
class AnimatedShellContainer extends StatefulWidget {
  /// Creates an animated shell branch container.
  const AnimatedShellContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  /// Active branch index in [children].
  final int currentIndex;

  /// Branch widgets to keep alive and cross-fade between.
  final List<Widget> children;

  @override
  State<AnimatedShellContainer> createState() => _AnimatedShellContainerState();
}

class _AnimatedShellContainerState extends State<AnimatedShellContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  late int _previousIndex = widget.currentIndex;

  @override
  void didUpdateWidget(covariant AnimatedShellContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < widget.children.length; i++) _buildBranch(i),
        ],
      ),
    );
  }

  Widget _buildBranch(int index) {
    final isCurrent = index == widget.currentIndex;
    final isAnimating = _controller.isAnimating;
    final isPrevious =
        isAnimating &&
        index == _previousIndex &&
        _previousIndex != widget.currentIndex;
    final isVisible = isCurrent || isPrevious;

    Widget child = widget.children[index];

    if (isAnimating) {
      if (isCurrent) {
        child = FadeThroughTransition(
          animation: _controller,
          secondaryAnimation: kAlwaysDismissedAnimation,
          child: child,
        );
      } else if (isPrevious) {
        child = FadeThroughTransition(
          animation: kAlwaysCompleteAnimation,
          secondaryAnimation: _controller,
          child: child,
        );
      }
    }

    return Offstage(
      offstage: !isVisible,
      child: TickerMode(
        enabled: isVisible,
        child: IgnorePointer(ignoring: !isCurrent, child: child),
      ),
    );
  }
}
