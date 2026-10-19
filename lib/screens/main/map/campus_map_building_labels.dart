import 'package:material_ui/material_ui.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/screens/main/map/campus_map_area_labels.dart';
import 'package:tattoo/screens/main/map/campus_map_labels.dart';
import 'package:tattoo/screens/main/map/campus_map_zoom.dart';

/// Building labels shrink toward campus overview and yield to indoor browsing.
class CampusMapBuildingLabels extends StatelessWidget {
  const CampusMapBuildingLabels({
    super.key,
    required this.buildings,
    this.selectedBuildingCode,
  });

  final List<CampusMapBuilding> buildings;
  final String? selectedBuildingCode;

  @override
  Widget build(BuildContext context) => CampusMapAreaLabels(
    areas: [
      for (final building in buildings)
        if (building.code != selectedBuildingCode)
          (
            name: campusMapBuildingName(
              building.code,
              fallbackName: building.name,
            ),
            polygons: building.polygons,
          ),
    ],
    scaleForZoom: campusMapBuildingLabelScale,
  );
}
