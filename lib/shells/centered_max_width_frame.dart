import 'package:flutter/material.dart';

/// Maximum width used by phone-oriented screen content.
const contentMaxWidth = 580.0;

/// Centers [child] while keeping it at or below [maxWidth].
///
/// The surrounding area keeps the current scaffold background color. This
/// widget only changes layout constraints and deliberately leaves [MediaQuery]
/// unchanged so safe areas, keyboard insets, and overlays keep the real window
/// metrics.
class CenteredMaxWidthFrame extends StatelessWidget {
  const CenteredMaxWidthFrame({
    super.key,
    required this.child,
    this.maxWidth = contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }
}
