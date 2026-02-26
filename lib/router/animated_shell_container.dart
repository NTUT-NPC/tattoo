import 'package:flutter/material.dart';

/// Handles tab switch animation and preserves state of each branch.
class AnimatedShellContainer extends StatefulWidget {
  const AnimatedShellContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<AnimatedShellContainer> createState() => _AnimatedShellContainerState();
}

class _AnimatedShellContainerState extends State<AnimatedShellContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
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
      final isForward = widget.currentIndex > _previousIndex;

      if (isCurrent) {
        final animation = CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        );
        child = FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(isForward ? 0.08 : -0.08, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      } else if (isPrevious) {
        final animation = CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInCubic,
        );
        child = FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0).animate(animation),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: Offset(isForward ? -0.04 : 0.04, 0),
            ).animate(animation),
            child: child,
          ),
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
