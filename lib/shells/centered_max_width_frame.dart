import 'package:material_ui/material_ui.dart';

/// Maximum width used by phone-oriented screen content.
const contentMaxWidth = 580.0;

/// Centers [child] while keeping it at or below [maxWidth].
///
/// The surrounding area keeps the current scaffold background color. Apart
/// from the horizontal insets consumed by [avoidHorizontalInsets], this widget
/// only changes layout constraints and leaves [MediaQuery] unchanged so top and
/// bottom safe areas, keyboard insets, and overlays keep the real window
/// metrics.
class CenteredMaxWidthFrame extends StatelessWidget {
  const CenteredMaxWidthFrame({
    super.key,
    required this.child,
    this.maxWidth = contentMaxWidth,
    this.avoidHorizontalInsets = true,
  });

  final Widget child;
  final double maxWidth;

  /// Keeps [child] clear of left and right safe-area insets such as display
  /// cutouts or a side system navigation bar.
  ///
  /// Only horizontal padding is consumed. Top and bottom insets stay in
  /// [MediaQuery] for the app bar and scroll padding to handle.
  final bool avoidHorizontalInsets;

  @override
  Widget build(BuildContext context) {
    Widget frame = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox.expand(child: child),
      ),
    );
    if (avoidHorizontalInsets) {
      frame = SafeArea(top: false, bottom: false, child: frame);
    }

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: frame,
    );
  }
}
