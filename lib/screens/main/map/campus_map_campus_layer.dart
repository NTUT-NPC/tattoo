import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/screens/main/map/campus_map_area_labels.dart';
import 'package:tattoo/screens/main/map/campus_map_zoom.dart';

/// Public campus boundaries replace building labels at the far overview scale.
class CampusMapCampusLayer extends StatelessWidget {
  const CampusMapCampusLayer({super.key, required this.campuses});

  final List<CampusMapCampus> campuses;

  @override
  Widget build(BuildContext context) {
    if (MapCamera.of(context).zoom >= campusMapBuildingLabelMinZoom) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    return Stack(
      fit: .expand,
      children: [
        IgnorePointer(
          child: PolygonLayer(
            polygons: [
              for (final campus in campuses)
                for (final polygon in campus.polygons)
                  Polygon(
                    points: [
                      for (final p in polygon.rings.first)
                        LatLng(p.latitude, p.longitude),
                    ],
                    holePointsList: [
                      for (final ring in polygon.rings.skip(1))
                        [for (final p in ring) LatLng(p.latitude, p.longitude)],
                    ],
                    color: colors.primary.withValues(alpha: 0.08),
                    borderColor: colors.primary,
                    borderStrokeWidth: 2,
                  ),
            ],
          ),
        ),
        CampusMapAreaLabels(
          areas: [
            for (final campus in campuses)
              (
                name: t.campusMap.campusNames[campus.code] ?? campus.name,
                polygons: campus.polygons,
              ),
          ],
          scaleForZoom: (_) => 1,
        ),
      ],
    );
  }
}
