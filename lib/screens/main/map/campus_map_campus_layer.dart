import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/screens/main/map/campus_map_area_labels.dart';
import 'package:tattoo/screens/main/map/campus_map_zoom.dart';

/// Public campus boundaries at overview scale, with a brief focus highlight.
///
/// Changing [focusedCampusCode] reveals that campus even when zoomed in. The
/// highlight holds for one second, with 200-millisecond fades at each end.
/// Changing [campusFocusRequest] repeats the highlight for the same campus.
/// [buildingLabels] yield while campus boundaries and names are displayed.
class CampusMapCampusLayer extends StatefulWidget {
  const CampusMapCampusLayer({
    super.key,
    required this.campuses,
    this.focusedCampusCode,
    this.campusFocusRequest = 0,
    this.buildingLabels,
  });

  final List<CampusMapCampus> campuses;
  final String? focusedCampusCode;
  final int campusFocusRequest;
  final Widget? buildingLabels;

  @override
  State<CampusMapCampusLayer> createState() => _CampusMapCampusLayerState();
}

class _CampusMapCampusLayerState extends State<CampusMapCampusLayer>
    with SingleTickerProviderStateMixin {
  late final _highlight =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..addStatusListener((status) {
        if (status == .completed) setState(() {});
      });
  late final _opacity = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 200,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 1000),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 200,
    ),
  ]).animate(_highlight);

  @override
  void initState() {
    super.initState();
    if (widget.focusedCampusCode != null) _highlight.forward();
  }

  @override
  void didUpdateWidget(covariant CampusMapCampusLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusedCampusCode != oldWidget.focusedCampusCode ||
        widget.campusFocusRequest != oldWidget.campusFocusRequest) {
      if (widget.focusedCampusCode == null) {
        _highlight.stop();
      } else {
        _highlight.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _highlight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MapCamera.of(context).zoom < campusMapBuildingLabelMinZoom) {
      return _CampusAreas(campuses: widget.campuses);
    }
    if (!_highlight.isAnimating) {
      return widget.buildingLabels ?? const SizedBox.shrink();
    }
    return FadeTransition(
      opacity: _opacity,
      child: _CampusAreas(
        campuses: [
          for (final campus in widget.campuses)
            if (campus.code == widget.focusedCampusCode) campus,
        ],
      ),
    );
  }
}

class _CampusAreas extends StatelessWidget {
  const _CampusAreas({required this.campuses});

  final List<CampusMapCampus> campuses;

  @override
  Widget build(BuildContext context) {
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
          fontSize: 12,
        ),
      ],
    );
  }
}
