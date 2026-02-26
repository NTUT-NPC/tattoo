import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A horizontally scrollable chip-style tab switcher.
///
/// Works with either:
/// 1. An explicit [controller], or
/// 2. A surrounding [DefaultTabController].
///
/// Example with `DefaultTabController`:
/// ```dart
/// const terms = ['114-2', '114-1', '113-2'];
///
/// DefaultTabController(
///   length: terms.length,
///   child: Scaffold(
///     appBar: AppBar(
///       title: const ChipTabSwitcher(tabs: terms),
///     ),
///     body: TabBarView(
///       children: [
///         for (final term in terms) Center(child: Text(term)),
///       ],
///     ),
///   ),
/// )
/// ```
///
/// Example with an external `TabController`:
/// ```dart
/// class TermSwitcherExample extends StatefulWidget {
///   const TermSwitcherExample({super.key});
///
///   @override
///   State<TermSwitcherExample> createState() => _TermSwitcherExampleState();
/// }
///
/// class _TermSwitcherExampleState extends State<TermSwitcherExample>
///     with SingleTickerProviderStateMixin {
///   static const terms = ['A', 'B', 'C'];
///   late final TabController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = TabController(length: terms.length, vsync: this);
///   }
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         ChipTabSwitcher(
///           tabs: terms,
///           controller: _controller,
///         ),
///         Expanded(
///           child: TabBarView(
///             controller: _controller,
///             children: [
///               for (final term in terms) Center(child: Text(term)),
///             ],
///           ),
///         ),
///       ],
///     );
///   }
/// }
/// ```
class ChipTabSwitcher extends StatefulWidget {
  const ChipTabSwitcher({
    super.key,
    required this.tabs,
    this.controller,
    this.visibleTabCount = 4.5,
    this.minTabWidth = 56,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.spacing = 8,
  });

  final List<String> tabs;
  final TabController? controller;
  final double visibleTabCount;
  final double minTabWidth;
  final EdgeInsetsGeometry padding;
  final double spacing;

  @override
  State<ChipTabSwitcher> createState() => _ChipTabSwitcherState();
}

class _ChipTabSwitcherState extends State<ChipTabSwitcher> {
  static const _chipTapAnimationDuration = Duration(milliseconds: 240);
  static const _scrollAnimationDuration = Duration(milliseconds: 220);
  static const _motionCurve = Curves.easeInOutCubic;

  TabController? _tabController;
  Animation<double>? _tabAnimation;
  int _activeIndex = 0;
  late List<GlobalKey> _tabKeys;

  @override
  void initState() {
    super.initState();
    _tabKeys = _buildTabKeys();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant ChipTabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _syncController();
    }
    if (oldWidget.tabs.length != widget.tabs.length) {
      _tabKeys = _buildTabKeys();
    }
  }

  @override
  void dispose() {
    _detachControllerListeners();
    super.dispose();
  }

  List<GlobalKey> _buildTabKeys() {
    return List<GlobalKey>.generate(widget.tabs.length, (_) => GlobalKey());
  }

  void _detachControllerListeners() {
    _tabController?.removeListener(_handleTabChange);
    _tabAnimation?.removeListener(_handleTabChange);
  }

  void _attachControllerListeners() {
    _tabController?.addListener(_handleTabChange);
    _tabAnimation?.addListener(_handleTabChange);
  }

  void _syncController() {
    final controller =
        widget.controller ?? DefaultTabController.maybeOf(context);

    if (_tabController == controller) {
      return;
    }

    _detachControllerListeners();
    _tabController = controller;
    _tabAnimation = controller?.animation;

    if (controller != null) {
      _activeIndex = _resolveActiveIndex(controller);
      _attachControllerListeners();
      _scrollTabIntoView(_activeIndex, animate: false);
    }
  }

  void _handleTabChange() {
    final controller = _tabController;
    if (controller == null || widget.tabs.isEmpty) {
      return;
    }

    final nextActiveIndex = _resolveActiveIndex(controller);
    if (_activeIndex == nextActiveIndex) {
      return;
    }

    setState(() {
      _activeIndex = nextActiveIndex;
    });
    _scrollTabIntoView(_activeIndex);
  }

  int _resolveActiveIndex(TabController controller) {
    final animationValue =
        controller.animation?.value ?? controller.index.toDouble();
    final roundedIndex = animationValue.round();
    return roundedIndex.clamp(0, widget.tabs.length - 1);
  }

  void _handleChipTap(int index) {
    final controller = _tabController;

    if (controller == null || index == _activeIndex) {
      return;
    }

    controller.animateTo(
      index,
      duration: _chipTapAnimationDuration,
      curve: _motionCurve,
    );
  }

  void _scrollTabIntoView(int index, {bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index < 0 || index >= _tabKeys.length) {
        return;
      }

      final tabContext = _tabKeys[index].currentContext;
      if (tabContext == null) {
        return;
      }

      Scrollable.ensureVisible(
        tabContext,
        duration: animate ? _scrollAnimationDuration : Duration.zero,
        curve: _motionCurve,
        alignment: 0.5,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    final controller = _tabController;
    if (controller == null) {
      throw FlutterError(
        'ChipTabSwitcher requires a TabController. '
        'Provide controller: or wrap with DefaultTabController.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxTabWidth = constraints.maxWidth / widget.visibleTabCount;
        final effectiveMaxTabWidth = math.max(maxTabWidth, widget.minTabWidth);
        final tabConstraints = BoxConstraints(
          minWidth: widget.minTabWidth,
          maxWidth: effectiveMaxTabWidth,
        );

        return SingleChildScrollView(
          padding: widget.padding,
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: widget.spacing,
            children: [
              for (var index = 0; index < widget.tabs.length; index++)
                ConstrainedBox(
                  key: _tabKeys[index],
                  constraints: tabConstraints,
                  child: _TabSwitchChip(
                    label: widget.tabs[index],
                    isSelected: index == _activeIndex,
                    onTap: () => _handleChipTap(index),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TabSwitchChip extends StatelessWidget {
  const _TabSwitchChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  static const _checkIconSize = 16.0;
  static const _checkSpacing = 4.0;
  static const _textUnselectedOffsetX = -(_checkIconSize + _checkSpacing) / 2;
  static const _borderRadius = 10.0;
  static const _containerAnimationDuration = Duration(milliseconds: 220);
  static const _checkAnimationDuration = Duration(milliseconds: 180);
  static const _motionCurve = Curves.easeInOutCubic;
  static const _chipPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 6);

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;
    final unselectedBorderColor = theme.colorScheme.outline.withValues(
      alpha: 0.45,
    );
    final backgroundColor = isSelected
        ? selectedColor.withValues(alpha: 0.1)
        : Colors.transparent;
    final borderColor = isSelected ? selectedColor : unselectedBorderColor;
    final borderWidth = isSelected ? 1.5 : 1.0;
    final labelColor = isSelected ? selectedColor : theme.colorScheme.onSurface;
    final labelWeight = isSelected ? FontWeight.w600 : FontWeight.w500;
    final textOffsetX = isSelected ? 0.0 : _textUnselectedOffsetX;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_borderRadius),
        onTap: onTap,
        child: AnimatedContainer(
          duration: _containerAnimationDuration,
          curve: _motionCurve,
          padding: _chipPadding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(_borderRadius),
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: _checkIconSize,
                height: _checkIconSize,
                child: AnimatedOpacity(
                  duration: _checkAnimationDuration,
                  curve: _motionCurve,
                  opacity: isSelected ? 1 : 0,
                  child: Icon(
                    Icons.check,
                    size: _checkIconSize,
                    color: selectedColor,
                  ),
                ),
              ),
              const SizedBox(width: _checkSpacing),
              TweenAnimationBuilder<double>(
                duration: _containerAnimationDuration,
                curve: _motionCurve,
                tween: Tween<double>(
                  end: textOffsetX,
                ),
                builder: (context, offsetX, child) {
                  return Transform.translate(
                    offset: Offset(offsetX, 0),
                    child: child,
                  );
                },
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: labelColor,
                    fontWeight: labelWeight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
