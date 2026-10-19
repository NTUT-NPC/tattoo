import 'package:material_ui/material_ui.dart';
import 'package:tattoo/components/chip_tab_switcher.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/utils/auto_spacing.dart';

/// Horizontal campus chips for the overview floating action bar.
///
/// Owns the [TabController] required by [ChipTabSwitcher] and keeps it in sync
/// with [selectedCampusCode] when the screen changes campuses programmatically.
class CampusMapCampusSelector extends StatefulWidget {
  const CampusMapCampusSelector({
    super.key,
    required this.campuses,
    required this.selectedCampusCode,
    required this.onSelected,
  });

  final List<CampusMapCampus> campuses;
  final String? selectedCampusCode;
  final ValueChanged<CampusMapCampus> onSelected;

  @override
  State<CampusMapCampusSelector> createState() =>
      _CampusMapCampusSelectorState();
}

class _CampusMapCampusSelectorState extends State<CampusMapCampusSelector>
    with TickerProviderStateMixin {
  late TabController _controller = _createController();

  int get _selectedIndex => widget.campuses
      .indexWhere((campus) => campus.code == widget.selectedCampusCode)
      .clamp(0, widget.campuses.length - 1);

  TabController _createController() => TabController(
    length: widget.campuses.length,
    initialIndex: _selectedIndex,
    vsync: this,
  )..addListener(_onTabChanged);

  void _onTabChanged() {
    final campus = widget.campuses[_controller.index];
    if (campus.code != widget.selectedCampusCode) {
      widget.onSelected(campus);
    }
  }

  @override
  void didUpdateWidget(covariant CampusMapCampusSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.campuses.length != widget.campuses.length) {
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
    tabs: [
      for (final campus in widget.campuses)
        (t.campusMap.campusNames[campus.code] ?? campus.name).spaced,
    ],
    controller: _controller,
    onReselected: (_) => _onTabChanged(),
    padding: const .symmetric(horizontal: 12),
  );
}
