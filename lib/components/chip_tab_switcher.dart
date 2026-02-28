import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

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
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.spacing = 8,
  });

  final List<String> tabs;
  final TabController? controller;
  final EdgeInsetsGeometry padding;
  final double spacing;

  @override
  State<ChipTabSwitcher> createState() => _ChipTabSwitcherState();
}

class _ChipTabSwitcherState extends State<ChipTabSwitcher> {
  static const _chipTapAnimationDuration = Duration(milliseconds: 240);
  static const _scrollAnimationDuration = Duration(milliseconds: 220);
  static const _motionCurve = Curves.easeInOutCubic;
  static const _visibleEdgeInset = 16.0;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _scrollViewportKey = GlobalKey();
  TabController? _tabController;
  Animation<double>? _tabAnimation;
  int _activeIndex = 0;
  int _scrollRequestEpoch = 0;
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
      final controller = _tabController;
      if (controller != null) {
        _activeIndex = _resolveActiveIndex(controller);
        _scrollTabIntoView(_activeIndex, animate: false);
      }
    }
  }

  @override
  void dispose() {
    _detachControllerListeners();
    _scrollController.dispose();
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
    if (widget.tabs.isEmpty) {
      return 0;
    }

    final maxIndex = widget.tabs.length - 1;
    if (controller.indexIsChanging) {
      return controller.index.clamp(0, maxIndex);
    }

    final animationValue =
        controller.animation?.value ?? controller.index.toDouble();
    return animationValue.round().clamp(0, maxIndex);
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
    final requestEpoch = ++_scrollRequestEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (requestEpoch != _scrollRequestEpoch) {
        return;
      }
      if (!mounted || index < 0 || index >= _tabKeys.length) {
        return;
      }
      if (!_scrollController.hasClients) {
        return;
      }

      final tabContext = _tabKeys[index].currentContext;
      final viewportContext = _scrollViewportKey.currentContext;
      if (tabContext == null || viewportContext == null) {
        return;
      }

      final tabBox = tabContext.findRenderObject() as RenderBox?;
      final viewportBox = viewportContext.findRenderObject() as RenderBox?;
      if (tabBox == null || viewportBox == null) {
        return;
      }

      final tabLeftInViewport = tabBox
          .localToGlobal(
            Offset.zero,
            ancestor: viewportBox,
          )
          .dx;
      final tabRightInViewport = tabLeftInViewport + tabBox.size.width;
      final viewportWidth = viewportBox.size.width;
      final minVisibleX = _visibleEdgeInset;
      final maxVisibleX = viewportWidth - _visibleEdgeInset;

      final targetOffset = switch (true) {
        _ when tabLeftInViewport < minVisibleX =>
          _scrollController.offset + (tabLeftInViewport - minVisibleX),
        _ when tabRightInViewport > maxVisibleX =>
          _scrollController.offset + (tabRightInViewport - maxVisibleX),
        _ => _scrollController.offset,
      };
      final clampedOffset = targetOffset.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );
      final resolvedOffset = clampedOffset.toDouble();

      if ((resolvedOffset - _scrollController.offset).abs() < 0.5) {
        return;
      }

      if (animate) {
        _scrollController.animateTo(
          resolvedOffset,
          duration: _scrollAnimationDuration,
          curve: _motionCurve,
        );
      } else {
        _scrollController.jumpTo(resolvedOffset);
      }
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

    return SingleChildScrollView(
      key: _scrollViewportKey,
      controller: _scrollController,
      padding: widget.padding,
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: widget.spacing,
        children: [
          for (var index = 0; index < widget.tabs.length; index++)
            SizedBox(
              key: _tabKeys[index],
              child: _TabSwitchChip(
                label: widget.tabs[index],
                isSelected: index == _activeIndex,
                onTap: () => _handleChipTap(index),
              ),
            ),
        ],
      ),
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

// Widget previews for _TabSwitchChip
void tabSwitchChipPreviewOnTap() {}

Widget _tabSwitchChipPreviewFrame({required Widget child}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: child,
      ),
    ),
  );
}

@Preview(
  name: '_TabSwitchChip selected',
  size: Size(220, 72),
  group: 'Single Chip',
)
Widget tabSwitchChipSelectedPreview() {
  return _tabSwitchChipPreviewFrame(
    child: _TabSwitchChip(
      label: '114-2',
      isSelected: true,
      onTap: tabSwitchChipPreviewOnTap,
    ),
  );
}

@Preview(
  name: '_TabSwitchChip unselected',
  size: Size(220, 72),
  group: 'Single Chip',
)
Widget tabSwitchChipUnselectedPreview() {
  return _tabSwitchChipPreviewFrame(
    child: _TabSwitchChip(
      label: '114-1',
      isSelected: false,
      onTap: tabSwitchChipPreviewOnTap,
    ),
  );
}

@Preview(name: 'ChipTabSwitcher', size: Size(220, 72), group: 'Tab Switcher')
Widget tabSwitcherPreview() {
  return _tabSwitchChipPreviewFrame(
    child: ChipTabSwitcher(
      tabs: ["114-1", "114-2", "113-1", "113-2", "112-1", "112-2"],
      // controller: TabController(length: 6, vsync: const TestVSync()),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      spacing: 12,
    ),
  );
}
