import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:tattoo/components/chip_tab_switcher.dart';
import 'package:tattoo/components/widget_preview_frame.dart';

/// A layout helper that overlays a floating action bar above a scrollable body.
///
/// The widget listens to descendant [ScrollNotification]s and uses vertical
/// drag updates to drive the bar visibility:
/// 1. Scrolling toward larger offsets hides the bar
/// 2. Scrolling back toward the top shows the bar
/// 3. Reaching the top always shows the bar
///
/// This keeps scroll-aware visibility behavior close to the floating bar
/// implementation instead of duplicating gesture logic in each screen.
class ScrollAwareFloatingActionBar extends StatefulWidget {
  /// Creates a layout with a scroll-aware floating action bar overlay.
  const ScrollAwareFloatingActionBar({
    super.key,
    required this.child,
    required this.floatingActionBarBuilder,
    this.margin = const EdgeInsets.all(16),
  });

  /// The scrollable content rendered behind the floating action bar.
  final Widget child;

  /// Builds the floating action bar using the resolved visibility state.
  ///
  /// Return null when the current screen state should not show a bar at all.
  final Widget? Function(BuildContext context, bool visible)
  floatingActionBarBuilder;

  /// Margin applied when positioning the floating action bar overlay.
  final EdgeInsetsGeometry margin;

  @override
  State<ScrollAwareFloatingActionBar> createState() =>
      _ScrollAwareFloatingActionBarState();
}

class _ScrollAwareFloatingActionBarState
    extends State<ScrollAwareFloatingActionBar> {
  static const _dragHideThreshold = 12.0;

  bool _isVisible = true;
  double _dragHideDelta = 0;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    final nextVisible = switch (notification) {
      OverscrollNotification(:final metrics) when metrics.pixels <= 0 => true,
      ScrollUpdateNotification(
        dragDetails: final DragUpdateDetails _,
        metrics: final metrics,
      )
          when metrics.pixels <= 0 =>
        true,
      ScrollUpdateNotification(
        dragDetails: final DragUpdateDetails _,
        scrollDelta: final scrollDelta?,
      ) =>
        scrollDelta < 0,
      _ => _isVisible,
    };

    if (nextVisible == _isVisible) {
      return false;
    }

    setState(() {
      _isVisible = nextVisible;
    });
    return false;
  }

  void _handleVerticalDragStart(DragStartDetails details) {
    _dragHideDelta = 0;
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta;
    if (delta == null || delta <= 0) {
      return;
    }

    _dragHideDelta += delta;
    if (_dragHideDelta < _dragHideThreshold || !_isVisible) {
      return;
    }

    setState(() {
      _isVisible = false;
    });
    _dragHideDelta = 0;
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    _dragHideDelta = 0;
  }

  void _showFloatingActionBar() {
    if (_isVisible) {
      return;
    }

    setState(() {
      _isVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final floatingActionBar = widget.floatingActionBarBuilder(
      context,
      _isVisible,
    );
    final resolvedMargin = widget.margin.resolve(Directionality.of(context));

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _showFloatingActionBar,
            child: widget.child,
          ),
          if (floatingActionBar case final floatingActionBar?)
            Positioned(
              left: resolvedMargin.left,
              top: resolvedMargin.top,
              right: resolvedMargin.right,
              bottom: resolvedMargin.bottom,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  ignoring: !_isVisible,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragStart: _handleVerticalDragStart,
                    onVerticalDragUpdate: _handleVerticalDragUpdate,
                    onVerticalDragEnd: _handleVerticalDragEnd,
                    child: floatingActionBar,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A bottom-floating action bar with one large pill surface and trailing actions.
///
/// The bar renders:
/// 1. A primary pill surface that hosts [child]
/// 2. Zero or more trailing action surfaces from [actions]
/// 3. Slide and fade visibility transitions controlled by [visible]
///
/// Example:
/// ```dart
/// FloatingActionBar(
///   visible: isVisible,
///   actions: [
///     FloatingActionBarActionButton(
///       icon: Icons.more_vert_outlined,
///       onTap: onMoreTap,
///     ),
///   ],
///   child: ChipTabSwitcher(
///     tabs: const ['114-2', '114-1', '113-2'],
///     padding: const EdgeInsets.symmetric(horizontal: 12),
///   ),
/// )
/// ```
class FloatingActionBar extends StatelessWidget {
  /// Creates a [FloatingActionBar] with one main content surface and
  /// optional trailing action surfaces.
  const FloatingActionBar({
    super.key,
    required this.child,
    this.actions = const [],
    this.visible = true,
    this.spacing = 8,
    this.contentPadding = const EdgeInsets.symmetric(vertical: 8),
  });

  static const _animationDuration = Duration(milliseconds: 200);
  static const _motionCurve = Curves.easeInOutCubic;

  /// The main content rendered inside the large pill surface.
  ///
  /// This is typically a horizontally scrollable control such as
  /// [ChipTabSwitcher].
  final Widget child;

  /// Trailing action widgets shown as separate floating surfaces.
  ///
  /// Use [FloatingActionBarActionButton] for the built-in circular action
  /// appearance.
  final List<Widget> actions;

  /// Whether the bar is interactive and visible.
  ///
  /// When false, the bar fades and slides downward, and pointer interaction is
  /// disabled.
  final bool visible;

  /// Spacing between the pill surface and action surfaces.
  final double spacing;

  /// Padding applied inside the pill surface.
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        duration: _animationDuration,
        curve: _motionCurve,
        offset: visible ? Offset.zero : const Offset(0, 1),
        child: AnimatedOpacity(
          duration: _animationDuration,
          curve: _motionCurve,
          opacity: visible ? 1 : 0,
          child: Row(
            spacing: spacing,
            children: [
              Expanded(
                child: _FloatingActionBarSurface(
                  shape: const StadiumBorder(),
                  child: Padding(
                    padding: contentPadding,
                    child: child,
                  ),
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

/// A circular trailing action button used by [FloatingActionBar].
class FloatingActionBarActionButton extends StatelessWidget {
  /// Creates a circular floating action button surface.
  const FloatingActionBarActionButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  /// The icon shown at the center of the button.
  final IconData icon;

  /// Called when the button is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 52,
      child: _FloatingActionBarSurface(
        shape: const CircleBorder(),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            splashFactory: InkRipple.splashFactory,
            splashColor: Colors.black12,
            highlightColor: Colors.black12,
            onTap: onTap,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final iconSize = constraints.biggest.shortestSide * 0.4;

                return Center(
                  child: Icon(icon, size: iconSize),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared shaped material surface used by the floating bar and action buttons.
class _FloatingActionBarSurface extends StatelessWidget {
  const _FloatingActionBarSurface({
    required this.shape,
    required this.child,
  });

  final ShapeBorder shape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.84),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

@Preview(
  name: 'FloatingActionBar',
  group: 'Floating Action Bar',
  size: Size(420, 120),
)
Widget previewFloatingActionBar() {
  const tabs = ['114-2', '114-1', '113-2', '113-1'];

  return WidgetPreviewFrame(
    child: SizedBox(
      width: 360,
      child: DefaultTabController(
        length: tabs.length,
        child: FloatingActionBar(
          actions: [
            FloatingActionBarActionButton(
              icon: Icons.share_outlined,
              onTap: () {},
            ),
            FloatingActionBarActionButton(
              icon: Icons.more_vert_outlined,
              onTap: () {},
            ),
          ],
          child: ChipTabSwitcher(
            tabs: tabs,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
    ),
  );
}

@Preview(
  name: 'ScrollAwareFloatingActionBar',
  group: 'Floating Action Bar',
  size: Size(420, 320),
)
Widget previewScrollAwareFloatingActionBar() {
  const tabs = ['114-2', '114-1', '113-2', '113-1'];

  return WidgetPreviewFrame(
    child: SizedBox(
      width: 360,
      height: 280,
      child: DefaultTabController(
        length: tabs.length,
        child: ScrollAwareFloatingActionBar(
          floatingActionBarBuilder: (context, visible) => FloatingActionBar(
            visible: visible,
            actions: [
              FloatingActionBarActionButton(
                icon: Icons.more_vert_outlined,
                onTap: () {},
              ),
            ],
            child: ChipTabSwitcher(
              tabs: tabs,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          child: ListView.builder(
            itemCount: 20,
            itemBuilder: (context, index) => ListTile(
              title: Text('Row $index'),
            ),
          ),
        ),
      ),
    ),
  );
}
