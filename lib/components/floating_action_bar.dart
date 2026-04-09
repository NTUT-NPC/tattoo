import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/widget_previews.dart';
import 'package:tattoo/components/chip_tab_switcher.dart';
import 'package:tattoo/components/widget_preview_frame.dart';

const _floatingActionBarPopupMenuMinWidth = 112.0;
const _floatingActionBarPopupMenuMaxWidth = 280.0;
const _floatingActionBarPopupMenuScreenPadding = 8.0;
const _floatingActionBarPopupMenuGap = 8.0;
const _floatingActionBarPopupMenuPadding = EdgeInsets.symmetric(vertical: 8.0);
const _floatingActionBarPopupMenuAnimationDuration = Duration(
  milliseconds: 220,
);

/// A layout helper that overlays a floating action bar above a scrollable body.
///
/// The widget keeps the bar visibility logic close to the layout instead of
/// duplicating it in each screen:
/// 1. Scrolling toward larger offsets hides the bar
/// 2. Scrolling back toward the top shows the bar
/// 3. Reaching the top always shows the bar
/// 4. Tapping the body reveals the bar again when it is hidden
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

  void _revealFloatingActionBar() {
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
            onTap: _revealFloatingActionBar,
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
///         FloatingActionBarMenuItem(
///           value: 'refresh',
///           label: 'Refresh',
///           icon: Icons.refresh_outlined,
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
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          splashFactory: InkRipple.splashFactory,
          splashColor: Colors.black12,
          highlightColor: Colors.black12,
          onTap: onTap,
          child: _FloatingActionBarActionIcon(icon: icon),
        ),
      ),
    );
  }
}

/// A menu item definition used by [FloatingActionBarMenuButton].
///
/// Each item maps a displayed label and optional icon to a typed [value] that
/// is returned to [FloatingActionBarMenuButton.onSelected].
class FloatingActionBarMenuItem<T> {
  /// Creates a floating action bar menu item.
  const FloatingActionBarMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
  });

  /// The value returned when the menu item is selected.
  final T value;

  /// The label shown in the popup menu.
  final String label;

  /// An optional leading icon shown next to the menu item label.
  final IconData? icon;

  /// Whether the item can be selected.
  final bool enabled;
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
    this.tooltip,
  });

  /// The icon shown at the center of the button.
  final IconData icon;

  /// The menu items shown when the button is tapped.
  ///
  /// Add more entries here to extend the popup menu without changing the
  /// button's public API.
  final List<FloatingActionBarMenuItem<T>> items;

  /// Called after the user selects a menu item.
  final ValueChanged<T> onSelected;

  /// Optional tooltip shown for long-press and accessibility affordances.
  final String? tooltip;

  bool get _enabled => items.any((item) => item.enabled);

  List<PopupMenuEntry<T>> _buildPopupMenuEntries() {
    return [
      for (final item in items)
        PopupMenuItem<T>(
          value: item.value,
          enabled: item.enabled,
          child: Row(
            spacing: 12,
            children: [
              if (item.icon case final icon?) Icon(icon, size: 20),
              Flexible(
                child: Text(
                  item.label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Future<void> _showPopupMenu(BuildContext context) async {
    if (!_enabled) {
      return;
    }

    final navigator = Navigator.of(context);
    final button = context.findRenderObject() as RenderBox?;
    final overlay = navigator.overlay?.context.findRenderObject() as RenderBox?;
    if (button == null || overlay == null) {
      return;
    }

    final entries = _buildPopupMenuEntries();
    final buttonRect = Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(
        button.size.bottomRight(Offset.zero),
        ancestor: overlay,
      ),
    );
    final mediaPadding = MediaQuery.paddingOf(context);
    final availableHeightAbove = math.max(
      0.0,
      buttonRect.top -
          mediaPadding.top -
          _floatingActionBarPopupMenuScreenPadding -
          _floatingActionBarPopupMenuGap,
    );
    final popupMenuConstraints = availableHeightAbove > 0
        ? BoxConstraints(
            minWidth: _floatingActionBarPopupMenuMinWidth,
            maxWidth: _floatingActionBarPopupMenuMaxWidth,
            maxHeight: availableHeightAbove,
          )
        : const BoxConstraints(
            minWidth: _floatingActionBarPopupMenuMinWidth,
            maxWidth: _floatingActionBarPopupMenuMaxWidth,
          );

    final selected = await navigator.push<T>(
      _FloatingActionBarMenuRoute<T>(
        anchorRect: buttonRect,
        items: entries,
        constraints: popupMenuConstraints,
        menuPadding: _floatingActionBarPopupMenuPadding,
        gap: _floatingActionBarPopupMenuGap,
        barrierLabelText: MaterialLocalizations.of(context).menuDismissLabel,
        capturedThemes: InheritedTheme.capture(
          from: context,
          to: navigator.context,
        ),
        elevation: 4,
        color: Colors.white.withValues(alpha: 0.96),
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    if (selected case final selected?) {
      onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tooltip = this.tooltip;
    final button = _FloatingActionBarCircularActionSurface(
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          splashFactory: InkRipple.splashFactory,
          splashColor: Colors.black12,
          highlightColor: Colors.black12,
          onTap: _enabled ? () => _showPopupMenu(context) : null,
          child: _FloatingActionBarActionIcon(icon: icon),
        ),
      ),
    );

    if (tooltip == null) {
      return button;
    }

    return Tooltip(
      message: tooltip,
      child: button,
    );
  }
}

class _FloatingActionBarMenuRoute<T> extends PopupRoute<T> {
  _FloatingActionBarMenuRoute({
    required this.anchorRect,
    required this.items,
    required this.constraints,
    required this.menuPadding,
    required this.gap,
    required this.barrierLabelText,
    required this.capturedThemes,
    required this.elevation,
    required this.color,
    required this.shadowColor,
    required this.surfaceTintColor,
    required this.shape,
  });

  final Rect anchorRect;
  final List<PopupMenuEntry<T>> items;
  final BoxConstraints constraints;
  final EdgeInsetsGeometry menuPadding;
  final double gap;
  final String barrierLabelText;
  final CapturedThemes capturedThemes;
  final double elevation;
  final Color color;
  final Color shadowColor;
  final Color surfaceTintColor;
  final ShapeBorder shape;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  String get barrierLabel => barrierLabelText;

  @override
  Duration get transitionDuration =>
      _floatingActionBarPopupMenuAnimationDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final menu = _FloatingActionBarPopupMenu<T>(
      animation: animation,
      items: items,
      constraints: constraints,
      menuPadding: menuPadding,
      elevation: elevation,
      color: color,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      shape: shape,
    );
    final mediaQuery = MediaQuery.of(context);

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomSingleChildLayout(
            delegate: _FloatingActionBarMenuRouteLayout(
              anchorRect: anchorRect,
              textDirection: Directionality.of(context),
              padding: mediaQuery.padding,
              gap: gap,
            ),
            child: capturedThemes.wrap(menu),
          );
        },
      ),
    );
  }
}

class _FloatingActionBarPopupMenu<T> extends StatelessWidget {
  const _FloatingActionBarPopupMenu({
    required this.animation,
    required this.items,
    required this.constraints,
    required this.menuPadding,
    required this.elevation,
    required this.color,
    required this.shadowColor,
    required this.surfaceTintColor,
    required this.shape,
  });

  final Animation<double> animation;
  final List<PopupMenuEntry<T>> items;
  final BoxConstraints constraints;
  final EdgeInsetsGeometry menuPadding;
  final double elevation;
  final Color color;
  final Color shadowColor;
  final Color surfaceTintColor;
  final ShapeBorder shape;

  @override
  Widget build(BuildContext context) {
    final size = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final opacity = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.7, curve: Curves.easeOut),
      reverseCurve: const Interval(0, 1, curve: Curves.easeIn),
    );
    final content = ConstrainedBox(
      constraints: constraints,
      child: IntrinsicWidth(
        stepWidth: 56,
        child: Semantics(
          role: SemanticsRole.menu,
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: MaterialLocalizations.of(context).popupMenuLabel,
          child: SingleChildScrollView(
            padding: menuPadding,
            child: ListBody(children: items),
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: opacity,
          child: Material(
            color: color,
            elevation: elevation,
            shadowColor: shadowColor,
            surfaceTintColor: surfaceTintColor,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            type: MaterialType.card,
            child: Align(
              alignment: AlignmentDirectional.bottomEnd,
              widthFactor: 1,
              heightFactor: size.value,
              child: child,
            ),
          ),
        );
      },
      child: content,
    );
  }
}

class _FloatingActionBarMenuRouteLayout extends SingleChildLayoutDelegate {
  _FloatingActionBarMenuRouteLayout({
    required this.anchorRect,
    required this.textDirection,
    required this.padding,
    required this.gap,
  });

  final Rect anchorRect;
  final TextDirection textDirection;
  final EdgeInsets padding;
  final double gap;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(
      constraints.biggest,
    ).deflate(
      const EdgeInsets.all(_floatingActionBarPopupMenuScreenPadding) + padding,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final left = anchorRect.left;
    final right = size.width - anchorRect.right;

    final x = switch (left.compareTo(right)) {
      > 0 => size.width - right - childSize.width,
      < 0 => left,
      _ => switch (textDirection) {
        TextDirection.rtl => size.width - right - childSize.width,
        TextDirection.ltr => left,
      },
    };
    final y = anchorRect.top - gap - childSize.height;

    return Offset(
      _clampHorizontal(size, childSize, x),
      _clampVertical(size, childSize, y),
    );
  }

  double _clampHorizontal(Size overlaySize, Size childSize, double x) {
    final minX = _floatingActionBarPopupMenuScreenPadding + padding.left;
    final maxX =
        overlaySize.width -
        childSize.width -
        _floatingActionBarPopupMenuScreenPadding -
        padding.right;

    return x.clamp(minX, maxX);
  }

  double _clampVertical(Size overlaySize, Size childSize, double y) {
    final minY = _floatingActionBarPopupMenuScreenPadding + padding.top;
    final maxY =
        overlaySize.height -
        childSize.height -
        _floatingActionBarPopupMenuScreenPadding -
        padding.bottom;

    return y.clamp(minY, maxY);
  }

  @override
  bool shouldRelayout(_FloatingActionBarMenuRouteLayout oldDelegate) {
    return anchorRect != oldDelegate.anchorRect ||
        textDirection != oldDelegate.textDirection ||
        padding != oldDelegate.padding ||
        gap != oldDelegate.gap;
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

class _FloatingActionBarActionIcon extends StatelessWidget {
  const _FloatingActionBarActionIcon({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = constraints.biggest.shortestSide * 0.4;

        return Center(
          child: Icon(icon, size: iconSize),
        );
      },
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
                FloatingActionBarMenuItem(
                  value: 'refresh',
                  label: 'Refresh',
                  icon: Icons.refresh_outlined,
                ),
                FloatingActionBarMenuItem(
                  value: 'display',
                  label: 'Display options',
                  icon: Icons.tune_outlined,
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
                  FloatingActionBarMenuItem(
                    value: 'refresh',
                    label: 'Refresh',
                    icon: Icons.refresh_outlined,
                  ),
                  FloatingActionBarMenuItem(
                    value: 'display',
                    label: 'Display options',
                    icon: Icons.tune_outlined,
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
