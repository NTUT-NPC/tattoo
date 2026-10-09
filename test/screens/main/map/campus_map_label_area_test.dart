import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/screens/main/map/campus_map_label_area.dart';

// campusMapInteriorLabelRect approximates the largest axis-aligned rectangle
// inside a room outline, so room labels never spill over L-shaped walls or
// courtyard holes. These tests use plain coordinates: each result must be big
// enough to be useful and must lie entirely inside the room.
void main() {
  test('finds a large interior rectangle in L and mirrored L rooms', () {
    final lShape = _ring(const [
      Offset(0, 0),
      Offset(100, 0),
      Offset(100, 28),
      Offset(28, 28),
      Offset(28, 100),
      Offset(0, 100),
    ]);
    final mirroredL = _ring(const [
      Offset(0, 0),
      Offset(100, 0),
      Offset(100, 100),
      Offset(72, 100),
      Offset(72, 28),
      Offset(0, 28),
    ]);

    for (final ring in [lShape, mirroredL]) {
      final rect = campusMapInteriorLabelRect([ring]);

      expect(rect, isNotNull);
      expect(rect!.width * rect.height, greaterThan(0.9 * 100 * 28));
      _expectRectangleInside(rect, [ring]);
    }
  });

  test('finds an interior rectangle inside a slanted room', () {
    final ring = _ring(const [
      Offset(0, 0),
      Offset(100, 20),
      Offset(90, 60),
      Offset(-10, 40),
    ]);
    final rect = campusMapInteriorLabelRect([ring]);

    expect(rect, isNotNull);
    expect(rect!.width * rect.height, greaterThan(1000));
    _expectRectangleInside(rect, [ring]);
  });

  test('finds a large rectangle around a polygon hole', () {
    final exterior = _ring(const [
      Offset(0, 0),
      Offset(120, 0),
      Offset(120, 120),
      Offset(0, 120),
    ]);
    final hole = _ring(const [
      Offset(40, 40),
      Offset(80, 40),
      Offset(80, 80),
      Offset(40, 80),
    ]);
    final rings = [exterior, hole];
    final rect = campusMapInteriorLabelRect(rings);

    expect(rect, isNotNull);
    expect(rect!.width * rect.height, greaterThan(1000));
    _expectRectangleInside(rect, rings);
  });

  test('excludes a hole smaller than one grid cell', () {
    final exterior = _ring(const [
      Offset(0, 0),
      Offset(120, 0),
      Offset(120, 120),
      Offset(0, 120),
    ]);
    final hole = _ring(const [
      Offset(40.1, 40.1),
      Offset(40.3, 40.1),
      Offset(40.3, 40.3),
      Offset(40.1, 40.3),
    ]);
    final rect = campusMapInteriorLabelRect([exterior, hole]);

    expect(rect, isNotNull);
    expect(
      rect!.overlaps(const Rect.fromLTRB(40.1, 40.1, 40.3, 40.3)),
      isFalse,
    );
    _expectRectangleInside(rect, [exterior, hole]);
  });

  test('fits a simple rectangular room close to its full area', () {
    const width = 100.0;
    const height = 80.0;
    final ring = _ring(const [
      Offset(0, 0),
      Offset(width, 0),
      Offset(width, height),
      Offset(0, height),
    ]);
    final rect = campusMapInteriorLabelRect([ring]);

    expect(rect, isNotNull);
    expect(rect!.left, lessThan(2));
    expect(rect.top, lessThan(2));
    expect(width - rect.right, lessThan(2));
    expect(height - rect.bottom, lessThan(2));
    expect(rect.width * rect.height, greaterThan(width * height * 0.9));
    _expectRectangleInside(rect, [ring]);
  });
}

void _expectRectangleInside(Rect rect, List<List<Offset>> rings) {
  final path = Path()..fillType = PathFillType.evenOdd;
  for (final ring in rings) {
    path.addPolygon(ring, true);
  }

  // Sample the whole rectangle, not just its corners, so an L cutout or hole
  // crossing the interior is caught.
  const samplesPerSide = 64;
  for (var x = 0; x < samplesPerSide; x++) {
    for (var y = 0; y < samplesPerSide; y++) {
      final point = Offset(
        rect.left + rect.width * (x + 0.5) / samplesPerSide,
        rect.top + rect.height * (y + 0.5) / samplesPerSide,
      );
      expect(
        path.contains(point),
        isTrue,
        reason: 'rectangle sample $point must be inside all room rings',
      );
    }
  }
}

List<Offset> _ring(List<Offset> vertices) => [...vertices, vertices.first];
