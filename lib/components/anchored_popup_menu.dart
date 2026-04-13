import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/widget_previews.dart';

import 'widget_preview_frame.dart';

const _anchoredPopupMenuMinWidth = 112.0;
const _anchoredPopupMenuMaxWidth = 280.0;
const _anchoredPopupMenuScreenPadding = 8.0;
const _anchoredPopupMenuGap = 8.0;
const _anchoredPopupMenuPadding = EdgeInsets.symmetric(vertical: 8.0);
const _anchoredPopupMenuAnimationDuration = Duration(milliseconds: 220);
const _anchoredPopupMenuShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
);

/// Controls how an [AnchoredPopupMenuButton] is sized and positioned.
enum AnchoredPopupMenuPlacement {
  /// Choose the side with more available vertical space.
  auto,

  /// Prefer showing the popup menu above the trigger.
  above,

  /// Prefer showing the popup menu below the trigger.
  below,
}

/// Configures sizing and placement behavior for [AnchoredPopupMenuButton].
@immutable
class AnchoredPopupMenuLayout {
  /// Creates the layout configuration for an anchored popup menu.
  const AnchoredPopupMenuLayout({
    this.minWidth = _anchoredPopupMenuMinWidth,
    this.maxWidth = _anchoredPopupMenuMaxWidth,
    this.screenPadding = _anchoredPopupMenuScreenPadding,
    this.gap = _anchoredPopupMenuGap,
    this.placement = AnchoredPopupMenuPlacement.auto,
  }) : assert(minWidth <= maxWidth),
       assert(screenPadding >= 0),
       assert(gap >= 0);

  /// Minimum popup menu width.
  final double minWidth;

  /// Maximum popup menu width.
  final double maxWidth;

  /// Minimum distance between the popup menu and the viewport edge.
  final double screenPadding;

  /// Gap between the trigger and popup menu.
  final double gap;

  /// Preferred vertical placement of the popup menu relative to its trigger.
  final AnchoredPopupMenuPlacement placement;

  /// Resolves the final menu placement for the current overlay and anchor.
  ///
  /// When [placement] is [AnchoredPopupMenuPlacement.auto], the menu is placed
  /// on the side with more available vertical space.
  AnchoredPopupMenuPlacement resolvePlacement({
    required Rect anchorRect,
    required Size overlaySize,
    required EdgeInsets mediaPadding,
  }) {
    return switch (placement) {
      .above => .above,
      .below => .below,
      .auto =>
        _availableHeightAbove(
                  anchorRect: anchorRect,
                  mediaPadding: mediaPadding,
                ) >=
                _availableHeightBelow(
                  anchorRect: anchorRect,
                  overlaySize: overlaySize,
                  mediaPadding: mediaPadding,
                )
            ? .above
            : .below,
    };
  }

  /// Resolves popup menu constraints for the current anchor and viewport.
  ///
  /// Width is always constrained by [minWidth] and [maxWidth]. Height is
  /// additionally constrained when there is vertical room on the chosen side.
  BoxConstraints resolveMenuConstraints({
    required Rect anchorRect,
    required Size overlaySize,
    required EdgeInsets mediaPadding,
  }) {
    final availableHeight = _availableHeight(
      anchorRect: anchorRect,
      overlaySize: overlaySize,
      mediaPadding: mediaPadding,
      placement: resolvePlacement(
        anchorRect: anchorRect,
        overlaySize: overlaySize,
        mediaPadding: mediaPadding,
      ),
    );

    if (availableHeight <= 0) {
      return BoxConstraints(
        minWidth: minWidth,
        maxWidth: maxWidth,
      );
    }

    return BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth,
      maxHeight: availableHeight,
    );
  }

  double _availableHeight({
    required Rect anchorRect,
    required Size overlaySize,
    required EdgeInsets mediaPadding,
    required AnchoredPopupMenuPlacement placement,
  }) {
    return math.max(
      0.0,
      switch (placement) {
        .auto => throw StateError(
          'AnchoredPopupMenuPlacement.auto must be resolved before layout.',
        ),
        .above => _availableHeightAbove(
          anchorRect: anchorRect,
          mediaPadding: mediaPadding,
        ),
        .below => _availableHeightBelow(
          anchorRect: anchorRect,
          overlaySize: overlaySize,
          mediaPadding: mediaPadding,
        ),
      },
    );
  }

  double _availableHeightAbove({
    required Rect anchorRect,
    required EdgeInsets mediaPadding,
  }) {
    return anchorRect.top - mediaPadding.top - screenPadding - gap;
  }

  double _availableHeightBelow({
    required Rect anchorRect,
    required Size overlaySize,
    required EdgeInsets mediaPadding,
  }) {
    return overlaySize.height -
        anchorRect.bottom -
        mediaPadding.bottom -
        screenPadding -
        gap;
  }
}

/// Controls the popup menu surface and transition styling.
@immutable
class AnchoredPopupMenuStyle {
  /// Creates the visual styling for an anchored popup menu.
  const AnchoredPopupMenuStyle({
    this.padding = _anchoredPopupMenuPadding,
    this.transitionDuration = _anchoredPopupMenuAnimationDuration,
    this.elevation = 4,
    this.color,
    this.shadowColor,
    this.surfaceTintColor = Colors.transparent,
    this.shape = _anchoredPopupMenuShape,
  }) : assert(elevation >= 0);

  /// App-wide floating popup menu styling shared by floating controls.
  static const floatingSurface = AnchoredPopupMenuStyle(
    color: Color(0xF5FFFFFF),
    shadowColor: Color(0x14000000),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  );

  /// Padding applied around the popup menu content.
  final EdgeInsetsGeometry padding;

  /// Duration of the popup menu route transition.
  final Duration transitionDuration;

  /// Material elevation applied to the popup menu surface.
  final double elevation;

  /// Popup menu background color.
  ///
  /// Falls back to `Theme.of(context).colorScheme.surface` when null.
  final Color? color;

  /// Popup menu shadow color.
  ///
  /// Falls back to the current theme shadow color when null.
  final Color? shadowColor;

  /// Popup menu surface tint color.
  final Color surfaceTintColor;

  /// Popup menu shape.
  final ShapeBorder shape;
}

/// A reusable popup menu trigger that opens a custom menu anchored to itself.
///
/// The public API is intentionally split into:
/// 1. Core behavior: [items], [onSelected], [triggerBuilder]
/// 2. Layout tweaks: [layout]
/// 3. Visual styling: [style]
///
/// The menu resolves its vertical placement from [layout], then keeps itself
/// inside the safe area and screen padding. Consumers provide the visual trigger
/// through [triggerBuilder], keeping menu behavior reusable across different
/// surfaces.
///
/// Example:
/// ```dart
/// AnchoredPopupMenuButton<String>(
///   items: const [
///     PopupMenuItem(
///       value: 'refresh',
///       child: Text('Refresh'),
///     ),
///   ],
///   onSelected: print,
///   style: const AnchoredPopupMenuStyle(
///     shape: RoundedRectangleBorder(
///       borderRadius: BorderRadius.all(Radius.circular(20)),
///     ),
///   ),
///   triggerBuilder: (context, onPressed) {
///     return FilledButton.icon(
///       onPressed: onPressed,
///       icon: const Icon(Icons.more_vert),
///       label: const Text('Open menu'),
///     );
///   },
/// )
/// ```
class AnchoredPopupMenuButton<T> extends StatelessWidget {
  /// Creates an anchored popup menu trigger.
  const AnchoredPopupMenuButton({
    super.key,
    required this.items,
    required this.onSelected,
    required this.triggerBuilder,
    this.enabled = true,
    this.tooltip,
    this.layout = const AnchoredPopupMenuLayout(),
    this.style = const AnchoredPopupMenuStyle(),
  });

  /// The popup menu entries shown when the trigger is pressed.
  final List<PopupMenuEntry<T>> items;

  /// Called with the selected value after the popup menu closes.
  final ValueChanged<T> onSelected;

  /// Builds the visual trigger.
  ///
  /// The callback is null when the menu is disabled and should be wired to the
  /// trigger's tap handler.
  final Widget Function(BuildContext context, VoidCallback? onPressed)
  triggerBuilder;

  /// Whether the trigger can open the popup menu.
  final bool enabled;

  /// Optional tooltip shown around the trigger.
  final String? tooltip;

  /// Sizing and positioning configuration for the popup menu.
  final AnchoredPopupMenuLayout layout;

  /// Surface and transition styling for the popup menu.
  final AnchoredPopupMenuStyle style;

  bool get _canOpen => enabled && items.isNotEmpty;

  Rect? _resolveAnchorRect(BuildContext context, NavigatorState navigator) {
    final button = context.findRenderObject() as RenderBox?;
    final overlay = navigator.overlay?.context.findRenderObject() as RenderBox?;
    if (button == null || overlay == null) {
      return null;
    }

    return Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(
        button.size.bottomRight(Offset.zero),
        ancestor: overlay,
      ),
    );
  }

  Future<void> _showPopupMenu(BuildContext context) async {
    if (!_canOpen) {
      return;
    }

    final navigator = Navigator.of(context);
    final anchorRect = _resolveAnchorRect(context, navigator);
    if (anchorRect == null) {
      return;
    }

    final selected = await navigator.push<T>(
      _AnchoredPopupMenuRoute<T>(
        anchorRect: anchorRect,
        items: items,
        layout: layout,
        style: style,
        barrierLabelText: MaterialLocalizations.of(context).menuDismissLabel,
        capturedThemes: InheritedTheme.capture(
          from: context,
          to: navigator.context,
        ),
      ),
    );

    if (selected case final selected?) {
      onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trigger = Builder(
      builder: (context) {
        return triggerBuilder(
          context,
          _canOpen ? () => _showPopupMenu(context) : null,
        );
      },
    );

    if (tooltip case final tooltip?) {
      return Tooltip(
        message: tooltip,
        child: trigger,
      );
    }

    return trigger;
  }
}

class _AnchoredPopupMenuRoute<T> extends PopupRoute<T> {
  _AnchoredPopupMenuRoute({
    required this.anchorRect,
    required this.items,
    required this.layout,
    required this.style,
    required this.barrierLabelText,
    required this.capturedThemes,
  });

  final Rect anchorRect;
  final List<PopupMenuEntry<T>> items;
  final AnchoredPopupMenuLayout layout;
  final AnchoredPopupMenuStyle style;
  final String barrierLabelText;
  final CapturedThemes capturedThemes;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  String get barrierLabel => barrierLabelText;

  @override
  Duration get transitionDuration => style.transitionDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final overlaySize = mediaQuery.size;
    final placement = layout.resolvePlacement(
      anchorRect: anchorRect,
      overlaySize: overlaySize,
      mediaPadding: mediaQuery.padding,
    );

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: CustomSingleChildLayout(
        delegate: _AnchoredPopupMenuRouteLayout(
          anchorRect: anchorRect,
          textDirection: Directionality.of(context),
          mediaPadding: mediaQuery.padding,
          layout: layout,
          placement: placement,
        ),
        child: capturedThemes.wrap(
          _AnchoredPopupMenu<T>(
            animation: animation,
            items: items,
            constraints: layout.resolveMenuConstraints(
              anchorRect: anchorRect,
              overlaySize: overlaySize,
              mediaPadding: mediaQuery.padding,
            ),
            style: style,
            placement: placement,
          ),
        ),
      ),
    );
  }
}

class _AnchoredPopupMenu<T> extends StatelessWidget {
  const _AnchoredPopupMenu({
    required this.animation,
    required this.items,
    required this.constraints,
    required this.style,
    required this.placement,
  });

  final Animation<double> animation;
  final List<PopupMenuEntry<T>> items;
  final BoxConstraints constraints;
  final AnchoredPopupMenuStyle style;
  final AnchoredPopupMenuPlacement placement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = style.color ?? theme.colorScheme.surface;
    final shadowColor =
        style.shadowColor ?? theme.shadowColor.withValues(alpha: 0.08);
    final growAlignment = switch (placement) {
      AnchoredPopupMenuPlacement.above => AlignmentDirectional.bottomEnd,
      AnchoredPopupMenuPlacement.below => AlignmentDirectional.topEnd,
      AnchoredPopupMenuPlacement.auto => AlignmentDirectional.bottomEnd,
    };
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

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: opacity,
          child: Material(
            color: color,
            elevation: style.elevation,
            shadowColor: shadowColor,
            surfaceTintColor: style.surfaceTintColor,
            shape: style.shape,
            clipBehavior: Clip.antiAlias,
            type: MaterialType.card,
            child: Align(
              alignment: growAlignment,
              widthFactor: 1,
              heightFactor: size.value,
              child: child,
            ),
          ),
        );
      },
      child: ConstrainedBox(
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
              padding: style.padding,
              child: ListBody(children: items),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnchoredPopupMenuRouteLayout extends SingleChildLayoutDelegate {
  _AnchoredPopupMenuRouteLayout({
    required this.anchorRect,
    required this.textDirection,
    required this.mediaPadding,
    required this.layout,
    required this.placement,
  });

  final Rect anchorRect;
  final TextDirection textDirection;
  final EdgeInsets mediaPadding;
  final AnchoredPopupMenuLayout layout;
  final AnchoredPopupMenuPlacement placement;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(
      constraints.biggest,
    ).deflate(EdgeInsets.all(layout.screenPadding) + mediaPadding);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final y = switch (placement) {
      AnchoredPopupMenuPlacement.above =>
        anchorRect.top - layout.gap - childSize.height,
      AnchoredPopupMenuPlacement.below => anchorRect.bottom + layout.gap,
      AnchoredPopupMenuPlacement.auto => anchorRect.top - layout.gap,
    };

    return Offset(
      _clampHorizontal(
        overlaySize: size,
        childSize: childSize,
        x: _resolveHorizontalOffset(size, childSize),
      ),
      _clampVertical(
        overlaySize: size,
        childSize: childSize,
        y: y,
      ),
    );
  }

  double _resolveHorizontalOffset(Size overlaySize, Size childSize) {
    final left = anchorRect.left;
    final right = overlaySize.width - anchorRect.right;

    return switch (left.compareTo(right)) {
      > 0 => overlaySize.width - right - childSize.width,
      < 0 => left,
      _ => switch (textDirection) {
        TextDirection.rtl => overlaySize.width - right - childSize.width,
        TextDirection.ltr => left,
      },
    };
  }

  double _clampHorizontal({
    required Size overlaySize,
    required Size childSize,
    required double x,
  }) {
    final minX = layout.screenPadding + mediaPadding.left;
    final maxX =
        overlaySize.width -
        childSize.width -
        layout.screenPadding -
        mediaPadding.right;

    return x.clamp(minX, maxX);
  }

  double _clampVertical({
    required Size overlaySize,
    required Size childSize,
    required double y,
  }) {
    final minY = layout.screenPadding + mediaPadding.top;
    final maxY =
        overlaySize.height -
        childSize.height -
        layout.screenPadding -
        mediaPadding.bottom;

    return y.clamp(minY, maxY);
  }

  @override
  bool shouldRelayout(_AnchoredPopupMenuRouteLayout oldDelegate) {
    return anchorRect != oldDelegate.anchorRect ||
        textDirection != oldDelegate.textDirection ||
        mediaPadding != oldDelegate.mediaPadding ||
        placement != oldDelegate.placement ||
        layout.gap != oldDelegate.layout.gap ||
        layout.screenPadding != oldDelegate.layout.screenPadding;
  }
}

@Preview(
  name: 'AnchoredPopupMenuButton',
  group: 'Popup Menu',
  size: Size(420, 220),
)
Widget previewAnchoredPopupMenuButton() {
  return WidgetPreviewFrame(
    child: Center(
      child: AnchoredPopupMenuButton<String>(
        items: const [
          PopupMenuItem(
            value: 'refresh',
            child: Text('Refresh'),
          ),
          PopupMenuItem(
            value: 'display',
            child: Text('Display options'),
          ),
        ],
        onSelected: (_) {},
        triggerBuilder: (context, onPressed) {
          return FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.more_vert_outlined),
            label: const Text('Open menu'),
          );
        },
      ),
    ),
  );
}
