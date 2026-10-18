import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

const _gridSize = 64;

/// Finds an approximate largest horizontal rectangle inside polygon [rings].
///
/// The first ring is the exterior; subsequent rings are holes. Coordinates use
/// the same projected pixel space as the returned rectangle. A bounded grid
/// excludes cells crossed by any boundary, then finds the largest rectangle of
/// interior cells. This keeps the entire label inside concave rooms and outside
/// holes. Returns `null` if no complete grid cell fits in the room.
Rect? campusMapInteriorLabelRect(List<List<Offset>> rings) {
  if (rings.isEmpty || rings.first.isEmpty) return null;
  final exterior = rings.first;
  final bounds = Rect.fromLTRB(
    exterior.map((point) => point.dx).reduce(math.min),
    exterior.map((point) => point.dy).reduce(math.min),
    exterior.map((point) => point.dx).reduce(math.max),
    exterior.map((point) => point.dy).reduce(math.max),
  );
  if (bounds.width <= 0 || bounds.height <= 0) return null;

  // Rectangular rooms need no grid search, including collinear wall vertices.
  var twiceArea = 0.0;
  for (var i = 0; i < exterior.length; i++) {
    final a = exterior[i] - exterior.first;
    final b = exterior[(i + 1) % exterior.length] - exterior.first;
    twiceArea += a.dx * b.dy - a.dy * b.dx;
  }
  final boundsArea = bounds.width * bounds.height;
  if (rings.length == 1 &&
      (twiceArea.abs() / 2 - boundsArea).abs() <= boundsArea * 1e-9) {
    return bounds;
  }

  final cellWidth = bounds.width / _gridSize;
  final cellHeight = bounds.height / _gridSize;
  final heights = List<int>.filled(_gridSize, 0);
  Rect? best;
  var bestArea = 0;

  for (var row = 0; row < _gridSize; row++) {
    final top = bounds.top + row * cellHeight;
    final bottom = bounds.top + (row + 1) * cellHeight;
    final middle = (top + bottom) / 2;
    final crossings = <double>[];
    final boundaryCells = List<int>.filled(_gridSize + 1, 0);

    for (final ring in rings) {
      for (var i = 0; i < ring.length; i++) {
        final a = ring[i];
        final b = ring[(i + 1) % ring.length];
        if ((a.dy > middle) != (b.dy > middle)) {
          crossings.add(
            a.dx + (middle - a.dy) * (b.dx - a.dx) / (b.dy - a.dy),
          );
        }

        final minY = math.min(a.dy, b.dy);
        final maxY = math.max(a.dy, b.dy);
        if (maxY <= top || minY >= bottom) continue;

        // Reject every cell intersected by the part of this edge in the band.
        // Checking only cell centers/corners would miss notches and small holes.
        double edgeX(double y) =>
            a.dx + (y - a.dy) * (b.dx - a.dx) / (b.dy - a.dy);
        final x1 = a.dy == b.dy ? a.dx : edgeX(math.max(top, minY));
        final x2 = a.dy == b.dy ? b.dx : edgeX(math.min(bottom, maxY));
        final first = ((math.min(x1, x2) - bounds.left) / cellWidth)
            .floor()
            .clamp(0, _gridSize);
        final after = ((math.max(x1, x2) - bounds.left) / cellWidth)
            .ceil()
            .clamp(0, _gridSize);
        if (first < after) {
          boundaryCells[first]++;
          boundaryCells[after]--;
        }
      }
    }

    crossings.sort();
    var crossing = 0;
    var boundaries = 0;
    for (var column = 0; column < _gridSize; column++) {
      final x = bounds.left + (column + 0.5) * cellWidth;
      while (crossing < crossings.length && crossings[crossing] <= x) {
        crossing++;
      }
      boundaries += boundaryCells[column];
      heights[column] = crossing.isOdd && boundaries == 0
          ? heights[column] + 1
          : 0;
    }

    // Each row is a histogram of uninterrupted interior cells above it. A
    // monotonic stack finds its largest rectangles in linear time.
    final stack = <int>[];
    for (var column = 0; column <= _gridSize; column++) {
      final height = column == _gridSize ? 0 : heights[column];
      while (stack.isNotEmpty && heights[stack.last] > height) {
        final rows = heights[stack.removeLast()];
        final left = stack.isEmpty ? 0 : stack.last + 1;
        final area = rows * (column - left);
        final width = (column - left) * cellWidth;
        if (area > bestArea ||
            (area == bestArea && width > (best?.width ?? 0))) {
          bestArea = area;
          best = Rect.fromLTRB(
            bounds.left + left * cellWidth,
            bounds.top + (row + 1 - rows) * cellHeight,
            bounds.left + column * cellWidth,
            bottom,
          );
        }
      }
      stack.add(column);
    }
  }
  return best;
}
