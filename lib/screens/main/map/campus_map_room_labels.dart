import 'dart:math' as math;
import 'dart:ui' as ui show Path;

import 'package:dart_polylabel2/dart_polylabel2.dart' as polylabel;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/screens/main/map/campus_map_label_area.dart';
import 'package:tattoo/screens/main/map/campus_map_labels.dart';
import 'package:tattoo/utils/auto_spacing.dart';

// Fit labels once at a classroom-detail scale, then scale the whole layout with
// the map. Reflowing at fractional camera zooms makes long names flicker.
const _roomLabelZoom = 20.0;

/// A centered, optionally rotated room label fitted to its projected outline.
class CampusMapRoomLabelLayout {
  const CampusMapRoomLabelLayout({
    required this.center,
    required this.angle,
    required this.clipPath,
    required this.textPainter,
  });

  /// The label center in the same coordinate system as the supplied rings.
  final Offset center;

  /// The upright room-axis rotation in radians.
  final double angle;

  /// The actual room boundary, with interior holes excluded.
  final ui.Path clipPath;

  /// The centered number and name, owned by the caller.
  final TextPainter textPainter;
}

/// Fits [number] above [name] at a room's center, using projected pixel [rings].
///
/// Keeps the original room-axis rotation for convex rooms. Concave rooms and
/// rooms with holes use horizontal text in an approximate largest interior
/// rectangle, so the entire number and name stay inside the room. Wrapping is
/// balanced within this area. The caller must dispose the returned painter.
CampusMapRoomLabelLayout layoutCampusMapRoomLabel({
  required List<List<Offset>> rings,
  required String number,
  required String name,
  required Color color,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final exterior = rings.first;
  final path = ui.Path()..fillType = PathFillType.evenOdd;
  for (final ring in rings) {
    path.addPolygon(ring, true);
  }
  final bounds = path.getBounds();
  var center = bounds.center;

  var sin = 0.0;
  var cos = 0.0;
  for (var i = 1; i < exterior.length; i++) {
    final edge = exterior[i] - exterior[i - 1];
    final angle = math.atan2(edge.dy, edge.dx);
    sin += edge.distance * math.sin(4 * angle);
    cos += edge.distance * math.cos(4 * angle);
  }
  var angle = math.atan2(sin, cos) / 4;
  Rect rotatedBounds(double radians) {
    final points = exterior.map((point) {
      final local = point - center;
      return Offset(
        local.dx * math.cos(radians) + local.dy * math.sin(radians),
        -local.dx * math.sin(radians) + local.dy * math.cos(radians),
      );
    }).toList();
    return (ui.Path()..addPolygon(points, true)).getBounds();
  }

  var area = rotatedBounds(angle);
  if (area.height > area.width) {
    angle += math.pi / 2;
    area = rotatedBounds(angle);
  }
  if (angle > math.pi / 2) angle -= math.pi;
  if (rings.length > 1 ||
      _isConcave(exterior) ||
      area.width < area.height * 2 ||
      angle.abs() < math.pi / 36) {
    angle = 0;
  }

  Offset rotate(Offset point, double radians) => Offset(
    point.dx * math.cos(radians) - point.dy * math.sin(radians),
    point.dx * math.sin(radians) + point.dy * math.cos(radians),
  );
  final localRings = [
    for (final ring in rings)
      [for (final point in ring) rotate(point - center, -angle)],
  ];
  area = campusMapInteriorLabelRect(localRings) ?? _interiorSquare(localRings);
  center += rotate(area.center, angle);
  final width = area.width * 0.88;
  final height = area.height * 0.88;
  var fontSize = math.min(14.0, math.min(width, height) / 4);
  TextPainter emptyPainter() => TextPainter(
    text: const TextSpan(text: ''),
    textDirection: TextDirection.ltr,
  )..layout();
  TextPainter createPainter() {
    if (width <= 0 || height <= 0) return emptyPainter();
    final characters = name.characters.toList();
    final perRow = math.max(1, (width / textScaler.scale(fontSize)).floor());
    final lines = math.max(1, (characters.length / perRow).ceil());
    final balanced = math.max(1, (characters.length / lines).ceil());
    final wrapped = [
      for (var start = 0; start < characters.length; start += balanced)
        characters
            .sublist(start, math.min(start + balanced, characters.length))
            .join(),
    ].join('\n');
    final text = [
      if (number.isNotEmpty && !name.contains(number)) number,
      if (wrapped.isNotEmpty) wrapped,
    ].join('\n');
    // An empty centered paragraph can produce a NaN paint offset in Flutter.
    // Unnamed map features still have geometry, but need no text layout.
    if (text.isEmpty) return emptyPainter();
    return TextPainter(
      text: TextSpan(
        text: text.spaced,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          height: 1.2,
          fontWeight: FontWeight.w500,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: width);
  }

  var painter = createPainter();
  // Re-measure after shrinking because wrapping can change the line count.
  while (painter.height > height && fontSize > 0.01) {
    fontSize *= 0.85;
    painter.dispose();
    painter = createPainter();
  }
  if (painter.height > height) {
    // Sub-pixel spaces cannot display readable text; don't paint a clipped name.
    painter.dispose();
    painter = emptyPainter();
  }
  return CampusMapRoomLabelLayout(
    center: center,
    angle: angle,
    clipPath: path,
    textPainter: painter,
  );
}

bool _isConcave(List<Offset> ring) {
  final length = ring.first == ring.last ? ring.length - 1 : ring.length;
  var positive = false;
  var negative = false;
  for (var i = 0; i < length; i++) {
    final incoming = ring[i] - ring[(i + length - 1) % length];
    final outgoing = ring[(i + 1) % length] - ring[i];
    final cross = incoming.dx * outgoing.dy - incoming.dy * outgoing.dx;
    if (cross > 1e-8) positive = true;
    if (cross < -1e-8) negative = true;
    if (positive && negative) return true;
  }
  return false;
}

Rect _interiorSquare(List<List<Offset>> rings) {
  // Very thin shapes may contain no full grid cell. A square inscribed in the
  // pole's clearance circle still fits, including when a room has tiny holes.
  final result = polylabel.polylabel([
    for (final ring in rings)
      [for (final point in ring) (x: point.dx, y: point.dy)],
  ], precision: 0.001);
  final size = math.max(0.0, result.distance) * math.sqrt2;
  return Rect.fromCenter(
    center: Offset(result.point.x, result.point.y),
    width: size,
    height: size,
  );
}

/// Draws visible selected-floor labels with stable wrapping during map gestures.
///
/// Layout uses a fixed projection scale; panning and zooming only transform the
/// cached result. Changing rooms, locale, theme, or text scaling rebuilds it.
class CampusMapRoomLabels extends StatefulWidget {
  const CampusMapRoomLabels({super.key, required this.rooms});
  final List<CampusMapRoom> rooms;

  @override
  State<CampusMapRoomLabels> createState() => _CampusMapRoomLabelsState();
}

class _CampusMapRoomLabelsState extends State<CampusMapRoomLabels> {
  final _cache = <CampusMapPolygon, CampusMapRoomLabelLayout>{};
  final _bounds = <CampusMapPolygon, LatLngBounds>{};
  Color? _color;
  TextScaler? _textScaler;
  Locale? _locale;

  void _clear() {
    for (final layout in _cache.values) {
      layout.textPainter.dispose();
    }
    _cache.clear();
  }

  @override
  void didUpdateWidget(covariant CampusMapRoomLabels oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rooms != widget.rooms) {
      _clear();
      _bounds.clear();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    _clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final color = Theme.of(context).colorScheme.onSurface;
    final scaler = MediaQuery.textScalerOf(context);
    final locale = Localizations.localeOf(context);
    if (_color != color || _textScaler != scaler || _locale != locale) {
      _clear();
      _color = color;
      _textScaler = scaler;
      _locale = locale;
    }
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _RoomLabelsPainter(
          camera,
          widget.rooms,
          color,
          scaler,
          locale,
          _cache,
          _bounds,
        ),
      ),
    );
  }
}

class _RoomLabelsPainter extends CustomPainter {
  _RoomLabelsPainter(
    this.camera,
    this.rooms,
    this.color,
    this.scaler,
    this.locale,
    this.cache,
    this.bounds,
  );
  final MapCamera camera;
  final List<CampusMapRoom> rooms;
  final Color color;
  final TextScaler scaler;
  final Locale locale;
  final Map<CampusMapPolygon, CampusMapRoomLabelLayout> cache;
  final Map<CampusMapPolygon, LatLngBounds> bounds;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = camera.getZoomScale(camera.zoom, _roomLabelZoom);
    for (final room in rooms) {
      for (final polygon in room.polygons) {
        final geographicBounds = bounds.putIfAbsent(
          polygon,
          () => LatLngBounds.fromPoints([
            for (final point in polygon.rings.first)
              LatLng(point.latitude, point.longitude),
          ]),
        );
        if (!camera.visibleBounds.isOverlapping(geographicBounds)) continue;
        Offset project(CampusMapPoint point) => camera.projectAtZoom(
          LatLng(point.latitude, point.longitude),
          _roomLabelZoom,
        );
        final origin = project(polygon.rings.first.first);
        final translation = origin * scale - camera.pixelOrigin;
        // Vertex-relative coordinates preserve precision and keep the layout
        // independent of both camera position and zoom.
        final layout = cache.putIfAbsent(
          polygon,
          () => layoutCampusMapRoomLabel(
            rings: [
              for (final ring in polygon.rings)
                [for (final point in ring) project(point) - origin],
            ],
            number: room.number,
            name: campusMapRoomName(room),
            color: color,
            textScaler: scaler,
          ),
        );
        if (layout.textPainter.size.isEmpty) continue;
        final roomBounds = layout.clipPath.getBounds();
        final screenBounds = Rect.fromPoints(
          roomBounds.topLeft * scale + translation,
          roomBounds.bottomRight * scale + translation,
        );
        if (!screenBounds.overlaps(Offset.zero & size)) {
          continue;
        }
        canvas.save();
        canvas.translate(translation.dx, translation.dy);
        canvas.scale(scale);
        canvas.clipPath(layout.clipPath);
        canvas.translate(layout.center.dx, layout.center.dy);
        canvas.rotate(layout.angle);
        layout.textPainter.paint(
          canvas,
          Offset(-layout.textPainter.width / 2, -layout.textPainter.height / 2),
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoomLabelsPainter oldDelegate) =>
      camera != oldDelegate.camera ||
      rooms != oldDelegate.rooms ||
      color != oldDelegate.color ||
      scaler != oldDelegate.scaler ||
      locale != oldDelegate.locale;
}
