import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/screens/main/map/campus_map_room_labels.dart';
import 'package:tattoo/screens/main/map/campus_map_tile_provider.dart';
import 'package:tattoo/utils/auto_spacing.dart';
import 'package:tattoo/utils/launch_url.dart';

/// Renders campus outlines and the currently selected building-floor only.
///
/// The renderer owns projection, polygon hit testing, viewport culling, and
/// zoom-dependent tile loading. Selection and data fetching belong to the screen.
class CampusMapViewport extends StatefulWidget {
  /// Creates a map with optional [tileProvider] injection for widget tests.
  const CampusMapViewport({
    super.key,
    required this.controller,
    required this.buildings,
    required this.rooms,
    required this.selectedBuildingCode,
    required this.selectedRoomId,
    required this.onBuildingSelected,
    required this.onRoomSelected,
    required this.onReady,
    required this.onUserCameraChanged,
    this.tileProvider,
  });

  final MapController controller;
  final List<CampusMapBuilding> buildings;
  final List<CampusMapRoom> rooms;
  final String? selectedBuildingCode;
  final String? selectedRoomId;
  final ValueChanged<CampusMapBuilding> onBuildingSelected;
  final ValueChanged<CampusMapRoom> onRoomSelected;
  final VoidCallback onReady;
  final ValueChanged<MapCamera> onUserCameraChanged;
  final TileProvider? tileProvider;

  @override
  State<CampusMapViewport> createState() => _CampusMapViewportState();
}

class _CampusMapViewportState extends State<CampusMapViewport> {
  final LayerHitNotifier<CampusMapBuilding> _buildingHits = ValueNotifier(null);
  final LayerHitNotifier<CampusMapRoom> _roomHits = ValueNotifier(null);
  late final TileProvider _tiles =
      widget.tileProvider ?? CampusMapTileProvider();

  @override
  void dispose() {
    _buildingHits.dispose();
    _roomHits.dispose();
    // TileLayer owns and disposes its TileProvider.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FlutterMap(
      mapController: widget.controller,
      options: MapOptions(
        initialCenter: const LatLng(25.0436, 121.5350),
        initialZoom: 17.5,
        minZoom: 15,
        maxZoom: 22,
        backgroundColor: colors.surfaceContainer,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onMapReady: widget.onReady,
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture) widget.onUserCameraChanged(camera);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'club.ntut.tattoo',
          maxNativeZoom: 19,
          panBuffer: 0,
          tileProvider: _tiles,
        ),
        GestureDetector(
          onTap: () {
            if (_buildingHits.value?.hitValues.firstOrNull
                case final building?) {
              widget.onBuildingSelected(building);
            }
          },
          child: PolygonLayer<CampusMapBuilding>(
            hitNotifier: _buildingHits,
            drawLabelsLast: true,
            polygons: [
              for (final building in widget.buildings)
                for (final polygon in building.polygons)
                  _polygon(
                    polygon,
                    hitValue: building,
                    fill: building.code == widget.selectedBuildingCode
                        ? colors.primaryContainer
                        : colors.surfaceContainerHighest,
                    border: colors.outline,
                    // Prepared components are ordered largest first. Label the
                    // main footprint once, rather than each detached stairway.
                    label: identical(polygon, building.polygons.first)
                        ? building.name.spaced
                        : '',
                    labelColor: colors.onSurface,
                  ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            if (_roomHits.value?.hitValues.firstOrNull case final room?) {
              widget.onRoomSelected(room);
            }
          },
          child: PolygonLayer<CampusMapRoom>(
            hitNotifier: _roomHits,
            drawLabelsLast: true,
            polygons: [
              for (final room in widget.rooms)
                for (final polygon in room.polygons)
                  _polygon(
                    polygon,
                    hitValue: room,
                    fill: room.id == widget.selectedRoomId
                        ? colors.tertiaryContainer
                        : colors.surface,
                    border: room.id == widget.selectedRoomId
                        ? colors.tertiary
                        : colors.outlineVariant,
                    label: '',
                    labelColor: colors.onSurface,
                  ),
            ],
          ),
        ),
        CampusMapRoomLabels(rooms: widget.rooms),
      ],
    );
  }

  Polygon<T> _polygon<T extends Object>(
    CampusMapPolygon polygon, {
    required T hitValue,
    required Color fill,
    required Color border,
    required String label,
    required Color labelColor,
  }) => Polygon<T>(
    points: polygon.rings.first.map(_point).toList(),
    holePointsList: polygon.rings
        .skip(1)
        .map((ring) => ring.map(_point).toList())
        .toList(),
    color: fill,
    borderColor: border,
    borderStrokeWidth: 1,
    label: label.isEmpty ? null : label,
    labelStyle: TextStyle(color: labelColor, fontSize: 12),
    labelPlacementCalculator: const PolygonLabelPlacementCalculator.polylabel(
      precision: 0.000001,
    ),
    hitValue: hitValue,
  );

  LatLng _point(CampusMapPoint point) =>
      LatLng(point.latitude, point.longitude);
}

/// Tile and data attribution drawn without a backdrop over the map.
class CampusMapAttribution extends StatelessWidget {
  const CampusMapAttribution({super.key});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () =>
        launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Text(
        '© OpenStreetMap contributors · NTUT',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    ),
  );
}
