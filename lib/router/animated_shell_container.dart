import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

// Handle tab switch animation and preserve state of each branch
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
  static const _duration = Duration(milliseconds: 200);

  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: _duration,
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _isAnimating = false;
          });
        }
      });

  late int _previousIndex = widget.currentIndex;
  var _isAnimating = false;

  @override
  void didUpdateWidget(covariant AnimatedShellContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.currentIndex == oldWidget.currentIndex) return;

    setState(() {
      _previousIndex = oldWidget.currentIndex;
      _isAnimating = true;
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++) _buildBranch(i),
      ],
    );
  }

  Widget _buildBranch(int index) {
    final isCurrent = index == widget.currentIndex;
    final isPrevious =
        _isAnimating &&
        index == _previousIndex &&
        _previousIndex != widget.currentIndex;
    final isVisible = isCurrent || isPrevious;

    Widget child = widget.children[index];

    if (_isAnimating && isCurrent) {
      child = FadeThroughTransition(
        animation: _controller,
        secondaryAnimation: ReverseAnimation(_controller),
        child: child,
      );
    } else if (_isAnimating && isPrevious) {
      child = FadeThroughTransition(
        animation: ReverseAnimation(_controller),
        secondaryAnimation: _controller,
        child: child,
      );
    }

    return Offstage(
      offstage: !isVisible,
      child: TickerMode(
        enabled: isVisible,
        child: IgnorePointer(
          ignoring: !isCurrent,
          child: child,
        ),
      ),
    );
  }
}
