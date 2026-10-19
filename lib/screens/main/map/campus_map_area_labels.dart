import 'package:dart_polylabel2/dart_polylabel2.dart' as polylabel;
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/utils/auto_spacing.dart';

/// Shared campus and building capsules, sized independently of their footprints.
///
/// Labels use the main polygon's interior anchor, including holes. Stable catalog
/// order resolves collisions by moving capsules to the nearest vertical gap.
/// The caller controls scale and layer order; labels do not intercept map taps.
/// White text on half-transparent black stays distinct from themed building fills.
class CampusMapAreaLabels extends StatefulWidget {
  const CampusMapAreaLabels({
    super.key,
    required this.areas,
    required this.scaleForZoom,
    this.emphasized = false,
  });

  final List<({String name, List<CampusMapPolygon> polygons})> areas;
  final double Function(double zoom) scaleForZoom;
  final bool emphasized;

  @override
  State<CampusMapAreaLabels> createState() => _CampusMapAreaLabelsState();
}

class _CampusMapAreaLabelsState extends State<CampusMapAreaLabels> {
  final _labels = <({LatLng anchor, TextPainter text, TextPainter? outline})>[];
  ColorScheme? _colors;
  TextScaler? _scaler;
  Locale? _locale;

  void _clear() {
    for (final label in _labels) {
      label.text.dispose();
      label.outline?.dispose();
    }
    _labels.clear();
  }

  @override
  void didUpdateWidget(covariant CampusMapAreaLabels oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.areas, widget.areas) ||
        oldWidget.emphasized != widget.emphasized) {
      _clear();
      _colors = null;
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    _clear();
    _colors = null;
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scaler = MediaQuery.textScalerOf(context);
    final locale = Localizations.localeOf(context);
    if (_colors != colors || _scaler != scaler || _locale != locale) {
      _clear();
      _colors = colors;
      _scaler = scaler;
      _locale = locale;
      for (final area in widget.areas) {
        if (area.polygons.isEmpty) continue;
        final name = area.name.spaced;
        if (name.isEmpty) continue;
        final pole = polylabel.polylabel([
          for (final ring in area.polygons.first.rings)
            [for (final point in ring) (x: point.longitude, y: point.latitude)],
        ], precision: 0.0000001);
        TextPainter layout(Paint? foreground) => TextPainter(
          text: TextSpan(
            text: name,
            style: TextStyle(
              color: foreground == null ? Colors.white : null,
              foreground: foreground,
              fontSize: 10,
              fontWeight: widget.emphasized ? .w600 : .w500,
            ),
          ),
          textAlign: .center,
          textDirection: Directionality.of(context),
          textScaler: scaler,
          locale: locale,
        )..layout(maxWidth: 160);
        final outline = widget.emphasized
            ? layout(
                Paint()
                  ..color = Colors.black
                  ..style = .stroke
                  ..strokeWidth = 0.5
                  ..strokeJoin = .round,
              )
            : null;
        _labels.add((
          anchor: LatLng(pole.point.y, pole.point.x),
          text: layout(null),
          outline: outline,
        ));
      }
    }
    final camera = MapCamera.of(context);
    return IgnorePointer(
      child: CustomPaint(
        size: .infinite,
        painter: _AreaLabelsPainter(
          camera,
          _labels,
          colors,
          widget.scaleForZoom(camera.zoom),
        ),
      ),
    );
  }
}

class _AreaLabelsPainter extends CustomPainter {
  _AreaLabelsPainter(this.camera, this.labels, this.colors, this.scale);

  final MapCamera camera;
  final List<({LatLng anchor, TextPainter text, TextPainter? outline})> labels;
  final ColorScheme colors;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    if (scale == 0) return;
    final occupied = <Rect>[];
    final placed =
        <
          ({Offset anchor, Rect rect, TextPainter text, TextPainter? outline})
        >[];
    for (final label in labels) {
      final anchor = camera.latLngToScreenOffset(label.anchor);
      final preferred = Rect.fromCenter(
        center: anchor,
        width: (label.text.width + 20) * scale,
        height: (label.text.height + 10) * scale,
      );
      if (!preferred.overlaps(Offset.zero & size)) continue;
      final rect = placeCampusMapAreaLabel(preferred, occupied, size);
      occupied.add(rect);
      placed.add((
        anchor: anchor,
        rect: rect,
        text: label.text,
        outline: label.outline,
      ));
    }
    // Draw every leader first so it cannot cross over another capsule's text.
    final leader = Paint()
      ..color = colors.outline
      ..strokeWidth = 1;
    for (final label in placed) {
      if ((label.rect.center - label.anchor).distance <= 12) continue;
      final edge = Offset(
        label.anchor.dx,
        label.anchor.dy < label.rect.top ? label.rect.top : label.rect.bottom,
      );
      canvas.drawLine(label.anchor, edge, leader);
    }
    final fill = Paint()..color = Colors.black.withValues(alpha: 0.5);
    for (final label in placed) {
      final capsule = RRect.fromRectAndRadius(
        label.rect,
        Radius.circular(label.rect.height / 2),
      );
      canvas.drawRRect(capsule, fill);
      canvas.save();
      canvas.translate(label.rect.center.dx, label.rect.center.dy);
      canvas.scale(scale);
      final offset = Offset(-label.text.width / 2, -label.text.height / 2);
      label.outline?.paint(canvas, offset);
      label.text.paint(canvas, offset);
      canvas.restore();
    }
  }

  // The state owns and mutates the cached layouts, so list identity alone cannot
  // detect a locale, text-scaling or catalog change.
  @override
  bool shouldRepaint(covariant _AreaLabelsPainter oldDelegate) => true;
}

/// Moves a capsule vertically into the closest gap, with six pixels of spacing.
///
/// Visible positions take priority. If the viewport cannot contain all labels,
/// packing continues beyond its edge instead of dropping colliding names.
Rect placeCampusMapAreaLabel(
  Rect preferred,
  List<Rect> occupied,
  Size viewport,
) {
  final candidates =
      <double>[
        preferred.top
            .clamp(
              0.0,
              (viewport.height - preferred.height).clamp(0.0, double.infinity),
            )
            .toDouble(),
        preferred.top,
        for (final other in occupied) ...[
          other.top - preferred.height - 6,
          other.bottom + 6,
        ],
      ]..sort((a, b) {
        final distance = (a - preferred.top).abs().compareTo(
          (b - preferred.top).abs(),
        );
        return distance != 0 ? distance : a.compareTo(b);
      });
  Rect at(double top) => preferred.shift(Offset(0, top - preferred.top));
  bool fits(Rect rect) =>
      !occupied.any((other) => other.inflate(3).overlaps(rect.inflate(3)));
  for (final top in candidates) {
    final rect = at(top);
    if (rect.top >= 0 && rect.bottom <= viewport.height && fits(rect)) {
      return rect;
    }
  }
  return candidates.map(at).firstWhere(fits);
}
