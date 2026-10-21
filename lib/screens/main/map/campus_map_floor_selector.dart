import 'package:material_ui/material_ui.dart';
import 'package:tattoo/components/chip_tab_switcher.dart';
import 'package:tattoo/models/campus_map.dart';

/// Horizontal floor chips for the current building's floating action bar.
///
/// Owns the [TabController] required by [ChipTabSwitcher] and keeps it in sync
/// with [selectedFloor] when the screen changes floors programmatically.
class CampusMapFloorSelector extends StatefulWidget {
  const CampusMapFloorSelector({
    super.key,
    required this.floors,
    required this.selectedFloor,
    required this.onSelected,
  });

  final List<CampusMapFloor> floors;
  final CampusMapFloor? selectedFloor;
  final ValueChanged<CampusMapFloor> onSelected;

  @override
  State<CampusMapFloorSelector> createState() => _CampusMapFloorSelectorState();
}

class _CampusMapFloorSelectorState extends State<CampusMapFloorSelector>
    with TickerProviderStateMixin {
  late TabController _controller = _createController();

  int get _selectedIndex => widget.floors
      .indexWhere((floor) => floor.layerName == widget.selectedFloor?.layerName)
      .clamp(0, widget.floors.length - 1);

  TabController _createController() => TabController(
    length: widget.floors.length,
    initialIndex: _selectedIndex,
    vsync: this,
  )..addListener(_onTabChanged);

  void _onTabChanged() {
    final floor = widget.floors[_controller.index];
    if (floor.layerName != widget.selectedFloor?.layerName) {
      widget.onSelected(floor);
    }
  }

  @override
  void didUpdateWidget(covariant CampusMapFloorSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.floors.length != widget.floors.length) {
      // ChipTabSwitcher detaches from the old controller during this rebuild.
      final old = _controller;
      _controller = _createController();
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    } else if (_controller.index != _selectedIndex) {
      _controller.animateTo(_selectedIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChipTabSwitcher(
    tabs: [for (final floor in widget.floors) floor.code],
    controller: _controller,
    padding: const .symmetric(horizontal: 12),
  );
}
