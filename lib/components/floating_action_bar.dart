import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:tattoo/components/anchored_popup_menu.dart';
import 'package:tattoo/components/chip_tab_switcher.dart';
import 'package:tattoo/components/widget_preview_frame.dart';

/// A layout helper that overlays a floating action bar above a scrollable body.
///
/// The widget keeps the bar visibility logic close to the layout instead of
/// duplicating it in each screen:
/// 1. Scrolling toward larger offsets hides the bar
/// 2. Scrolling back toward the top shows the bar
/// 3. Reaching the top always shows the bar
/// 4. Tapping the body toggles the bar visibility
/// 5. Swiping horizontally to change pages reveals the bar when hidden
///
/// The [floatingActionBarBuilder] receives the resolved visibility state so the
/// caller can decide whether to render a [FloatingActionBar] or omit the bar
/// entirely for the current screen state.
///
/// Example:
/// ```dart
/// ScrollAwareFloatingActionBar(
///   floatingActionBarBuilder: (context, visible) => FloatingActionBar(
///     visible: visible,
///     child: ChipTabSwitcher(
///       tabs: const ['114-2', '114-1', '113-2'],
///     ),
///   ),
///   child: ListView.builder(
///     itemCount: 20,
///     itemBuilder: (context, index) => ListTile(
///       title: Text('Row $index'),
///     ),
///   ),
/// )
/// ```
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
    if (notification.metrics.axis == Axis.horizontal &&
        !_isVisible &&
        notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      setState(() {
        _isVisible = true;
      });
      return false;
    }

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

  void _toggleFloatingActionBar() {
    setState(() {
      _isVisible = !_isVisible;
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
            onTap: _toggleFloatingActionBar,
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

/// A bottom-floating action bar with one large pill surface and trailing
/// circular actions.
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
///     FloatingActionBarMenuButton<String>(
///       icon: Icons.more_vert_outlined,
///       items: const [
///         PopupMenuItem(
///           value: 'refresh',
///           child: ListTile(
///             leading: Icon(Icons.refresh_outlined),
///             title: Text('Refresh'),
///           ),
///         ),
///       ],
///       onSelected: onMenuSelected,
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
  /// Use [FloatingActionBarActionButton] for tap actions and
  /// [FloatingActionBarMenuButton] for popup menus.
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
///
/// Use this for a single tap action that should share the floating action bar's
/// circular surface style.
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
    return _FloatingActionBarCircularActionSurface(
      child: _FloatingActionBarIconButton(
        icon: icon,
        onTap: onTap,
      ),
    );
  }
}

/// A circular trailing action that expands into a popup menu.
///
/// This is the menu counterpart to [FloatingActionBarActionButton]. It reuses
/// the same circular surface style, but opens a popup menu built from [items]
/// and reports the selected item's value through [onSelected].
///
/// Multiple action buttons and menu buttons can be mixed in
/// [FloatingActionBar.actions].
class FloatingActionBarMenuButton<T> extends StatelessWidget {
  /// Creates a menu action button for [FloatingActionBar].
  const FloatingActionBarMenuButton({
    super.key,
    required this.icon,
    required this.items,
    required this.onSelected,
    this.enabled = true,
    this.tooltip,
    this.style = AnchoredPopupMenuStyle.floatingSurface,
  });

  /// The icon shown at the center of the button.
  final IconData icon;

  /// The popup menu entries shown when the button is tapped.
  final List<PopupMenuEntry<T>> items;

  /// Called after the user selects a menu item.
  final ValueChanged<T> onSelected;

  /// Whether the trigger can open the popup menu.
  final bool enabled;

  /// Optional tooltip shown for long-press and accessibility affordances.
  final String? tooltip;

  /// Popup menu styling shared across floating action surfaces.
  final AnchoredPopupMenuStyle style;

  @override
  Widget build(BuildContext context) {
    return AnchoredPopupMenuButton<T>(
      items: items,
      onSelected: onSelected,
      enabled: enabled,
      tooltip: tooltip,
      style: style,
      triggerBuilder: (context, onPressed) {
        return _FloatingActionBarCircularActionSurface(
          child: _FloatingActionBarIconButton(
            icon: icon,
            onTap: onPressed,
          ),
        );
      },
    );
  }
}

class _FloatingActionBarCircularActionSurface extends StatelessWidget {
  const _FloatingActionBarCircularActionSurface({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 52,
      child: _FloatingActionBarSurface(
        shape: const CircleBorder(),
        child: child,
      ),
    );
  }
}

class _FloatingActionBarIconButton extends StatelessWidget {
  const _FloatingActionBarIconButton({
    required this.icon,
    required this.onTap,
  });

  static const _iconSize = 20.0;

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        splashFactory: InkRipple.splashFactory,
        splashColor: Colors.black12,
        highlightColor: Colors.black12,
        onTap: onTap,
        child: Center(
          child: Icon(icon, size: _iconSize),
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
            FloatingActionBarMenuButton<String>(
              icon: Icons.more_vert_outlined,
              items: const [
                PopupMenuItem(
                  value: 'refresh',
                  child: const ListTile(
                    leading: Icon(Icons.refresh_outlined),
                    title: Text('Refresh'),
                  ),
                ),
                PopupMenuItem(
                  value: 'display',
                  child: const ListTile(
                    leading: Icon(Icons.tune_outlined),
                    title: Text('Display options'),
                  ),
                ),
              ],
              onSelected: (_) {},
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
              FloatingActionBarMenuButton<String>(
                icon: Icons.more_vert_outlined,
                items: const [
                  PopupMenuItem(
                    value: 'refresh',
                    child: const ListTile(
                      leading: Icon(Icons.refresh_outlined),
                      title: Text('Refresh'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'display',
                    child: const ListTile(
                      leading: Icon(Icons.tune_outlined),
                      title: Text('Display options'),
                    ),
                  ),
                ],
                onSelected: (_) {},
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
