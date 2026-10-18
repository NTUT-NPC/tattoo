import 'package:material_ui/material_ui.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/screens/main/map/campus_map_area_labels.dart';
import 'package:tattoo/screens/main/map/campus_map_labels.dart';
import 'package:tattoo/screens/main/map/campus_map_zoom.dart';

/// Building labels shrink toward campus overview and remain below indoor floors.
class CampusMapBuildingLabels extends StatelessWidget {
  const CampusMapBuildingLabels({super.key, required this.buildings});

  final List<CampusMapBuilding> buildings;

  @override
  Widget build(BuildContext context) => CampusMapAreaLabels(
    areas: [
      for (final building in buildings)
        (
          name: campusMapBuildingName(
            building.code,
            fallbackName: building.name,
          ),
          polygons: building.polygons,
        ),
    ],
    scaleForZoom: campusMapBuildingLabelScale,
    emphasized: true,
  );
}
