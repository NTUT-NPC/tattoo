import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/repositories/map_repository.dart';
import 'package:tattoo/services/map/campus_map_service.dart';
import 'package:tattoo/i18n/strings.g.dart';

class SelectedFloorNotifier extends Notifier<String> {
  @override
  String build() => '1F';
  void set(String floor) => state = floor;
}

final selectedFloorProvider = NotifierProvider<SelectedFloorNotifier, String>(
  SelectedFloorNotifier.new,
);

class MapSettingsNotifier
    extends Notifier<({bool showBuildings, bool showBasemap})> {
  @override
  ({bool showBuildings, bool showBasemap}) build() =>
      (showBuildings: true, showBasemap: true);
  void toggleBuildings() => state = (
    showBuildings: !state.showBuildings,
    showBasemap: state.showBasemap,
  );
  void toggleBasemap() => state = (
    showBuildings: state.showBuildings,
    showBasemap: !state.showBasemap,
  );
}

final mapSettingsProvider =
    NotifierProvider<
      MapSettingsNotifier,
      ({bool showBuildings, bool showBasemap})
    >(
      MapSettingsNotifier.new,
    );

final campusMapInitProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(campusMapRepositoryProvider);

  // Ensure disk cache is loaded into memory first
  await repo.init();

  // ONLY fetch from network if we don't have it locally
  if (repo.getBuildingsSync() == null) {
    await repo.getBuildings();
  }

  // Prioritize 1F if not in cache
  if (repo.getRoomsSync('1F') == null) {
    await repo.getRoomsForFloor('1F');
  }

  // Fetch the rest in the background if not fully cached
  if (!repo.allRoomsFetched) {
    await repo.prefetchAll();
  }
});

final campusRoomsProvider = Provider<List<FeatureDto>>((ref) {
  final repo = ref.watch(campusMapRepositoryProvider);
  final floor = ref.watch(selectedFloorProvider);

  // If we have it in cache (from prefetch or previous individual fetch), use it
  final cached = repo.getRoomsSync(floor);
  if (cached != null) return cached;

  // Otherwise, kick off an individual fetch and listen for result
  // This ensures the first floor shown is fast.
  ref.read(campusMapInitProvider); // kick off buildings too

  final asyncValue = ref.watch(
    FutureProvider((ref) => repo.getRoomsForFloor(floor)),
  );
  return asyncValue.value ?? [];
});

class CampusMapScreen extends ConsumerStatefulWidget {
  const CampusMapScreen({super.key});

  @override
  ConsumerState<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends ConsumerState<CampusMapScreen> {
  final _transformationController = TransformationController();

  // Hardcoded EPSG:3857 Web Mercator bounds matching the Python script (padded campus bbox)
  static const double minX = 13528972.133;
  static const double maxX = 13529653.408;
  static const double minY = 2880827.574;
  static const double maxY = 2881215.025;

  static const bbox3857 = (
    minX: minX,
    maxX: maxX,
    minY: minY,
    maxY: maxY,
  );

  @override
  Widget build(BuildContext context) {
    final initAsync = ref.watch(campusMapInitProvider);
    final rooms = ref.watch(campusRoomsProvider);
    final selectedFloor = ref.watch(selectedFloorProvider);
    final settings = ref.watch(mapSettingsProvider);

    // Calculate fixed aspect ratio size for the canvas based on the bbox
    final double widthSpan = maxX - minX;
    final double heightSpan = maxY - minY;
    final double aspect = widthSpan / heightSpan;

    // Base logical width, can rely on zooming for details
    final double canvasWidth = 4000.0;
    final double canvasHeight = canvasWidth / aspect;

    final basemapTiles = <Widget>[];
    if (settings.showBasemap) {
      const int z = 19;
      final double span = 40075016.68557849 / pow(2, z);
      const double originShift = 20037508.342789244;

      for (int tx = 439138; tx <= 439148; tx++) {
        for (int ty = 224449; ty <= 224456; ty++) {
          final tileMinX = tx * span - originShift;
          final tileMaxY = originShift - ty * span; // Top edge of tile
          final tileMaxX = tileMinX + span;
          final tileMinY = tileMaxY - span; // Bottom edge of tile

          if (tileMaxX < minX ||
              tileMinX > maxX ||
              tileMaxY < minY ||
              tileMinY > maxY) {
            continue;
          }

          final left = (tileMinX - minX) / widthSpan * canvasWidth;
          final right = (tileMaxX - minX) / widthSpan * canvasWidth;
          final top = (maxY - tileMaxY) / heightSpan * canvasHeight;
          final bottom = (maxY - tileMinY) / heightSpan * canvasHeight;

          basemapTiles.add(
            Positioned(
              left: left,
              top: top,
              width: right - left,
              height: bottom - top,
              child: CachedNetworkImage(
                imageUrl:
                    'https://a.basemaps.cartocdn.com/rastertiles/voyager/$z/$tx/$ty@2x.png',
                fit: BoxFit.fill,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                errorWidget: (context, url, error) => const SizedBox(),
              ),
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.map.title)),
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            constrained:
                false, // allow the content to be its chosen size instead of restricted by screen
            maxScale: 10.0,
            minScale: 0.1,
            boundaryMargin: EdgeInsets.zero,
            child: RepaintBoundary(
              child: SizedBox(
                width: canvasWidth,
                height: canvasHeight,
                child: Stack(
                  children: [
                    ...basemapTiles,
                    Positioned.fill(
                      child: CustomPaint(
                        isComplex: true,
                        willChange: false,
                        painter: _MapPainter(
                          buildings: settings.showBuildings
                              ? (ref
                                        .read(campusMapRepositoryProvider)
                                        .getBuildingsSync() ??
                                    [])
                              : [],
                          rooms: rooms,
                          bbox: bbox3857,
                        ),
                        size: Size(canvasWidth, canvasHeight),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (initAsync.isLoading)
            const Positioned(
              left: 16,
              bottom: 16,
              child: CircularProgressIndicator(),
            ),

          Positioned(
            right: 16,
            top: 16,
            bottom: 16,
            child: Center(
              child: Card(
                child: SizedBox(
                  width: 50,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: CampusMapRepository.floorOrder.length,
                    itemBuilder: (context, index) {
                      final floor = CampusMapRepository.floorOrder[index];
                      final isSelected = floor == selectedFloor;
                      return InkWell(
                        onTap: () =>
                            ref.read(selectedFloorProvider.notifier).set(floor),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: Text(floor, textAlign: TextAlign.center),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.buildings,
    required this.rooms,
    required this.bbox,
  });

  final List<FeatureDto> buildings;
  final List<FeatureDto> rooms;
  final ({double minX, double maxX, double minY, double maxY}) bbox;

  @override
  void paint(Canvas canvas, Size size) {
    // Style matching python CSS:
    // .building { fill: #f0f4f8; stroke: #d1dce5; stroke-width: 2; }
    // .room     { fill: #ffffff; fill-opacity: 0.8; stroke: #bcccdc; stroke-width: 1; }
    // .label    { fill: #334e68; }

    final pFillB = Paint()..color = const Color(0xFFF0F4F8);
    final pStrokeB = Paint()
      ..color = const Color(0xFFD1DCE5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final pFillR = Paint()..color = const Color(0xCCFFFFFF);
    final pStrokeR = Paint()
      ..color = const Color(0xFFBCCCDC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    void draw(
      List<FeatureDto> fs,
      Paint fill,
      Paint stroke, {
      bool label = false,
    }) {
      for (final f in fs) {
        for (final poly in f.polygons) {
          if (poly.isEmpty) continue;
          final path = Path();
          final start = _project(poly[0], size);
          path.moveTo(start.dx, start.dy);
          for (int i = 1; i < poly.length; i++) {
            final p = _project(poly[i], size);
            path.lineTo(p.dx, p.dy);
          }
          path.close();
          canvas.drawPath(path, fill);
          canvas.drawPath(path, stroke);

          if (label) {
            // ── 1. Extract fields with case-insensitive / keyword fallback ──
            String? findProp(List<String> keywords) {
              for (final k in keywords) {
                final match = f.properties.entries.where(
                  (e) => e.key.toLowerCase() == k.toLowerCase(),
                );
                if (match.isNotEmpty && match.first.value != null) {
                  final val = match.first.value.toString().trim();
                  if (val.isNotEmpty) return val;
                }
              }
              // Secondary search: find any key that CONTAINS the keyword
              for (final k in keywords) {
                final match = f.properties.entries.where(
                  (e) => e.key.toLowerCase().contains(k.toLowerCase()),
                );
                if (match.isNotEmpty && match.first.value != null) {
                  final val = match.first.value.toString().trim();
                  if (val.isNotEmpty) return val;
                }
              }
              return null;
            }

            final roomName =
                findProp([
                  'room_name',
                  'name',
                  'title',
                  'room_title',
                  'teacher',
                  'ch_name',
                  'cname',
                  'note',
                  'remark',
                ]) ??
                '';

            final roomNo =
                findProp([
                  'class_num',
                  'room_no',
                  'room_num',
                  'num',
                  'no',
                ])?.replaceAll('-', '\u2011').replaceAll(' ', '\u00A0') ??
                '';

            final roomId =
                f.properties['room_id']?.toString() ??
                f.properties['id']?.toString() ??
                f.id;

            if (roomName.isEmpty && roomNo.isEmpty && roomId.isEmpty) continue;

            // ── 2. Compute pixel bbox and OBB (oriented bounding box) ─────────
            double pxMinX = double.infinity, pxMaxX = double.negativeInfinity;
            double pxMinY = double.infinity, pxMaxY = double.negativeInfinity;
            final projectedPoly = poly.map((p) => _project(p, size)).toList();
            for (final pp in projectedPoly) {
              if (pp.dx < pxMinX) pxMinX = pp.dx;
              if (pp.dx > pxMaxX) pxMaxX = pp.dx;
              if (pp.dy < pxMinY) pxMinY = pp.dy;
              if (pp.dy > pxMaxY) pxMaxY = pp.dy;
            }
            final polyW = pxMaxX - pxMinX;
            final polyH = pxMaxY - pxMinY;
            if (polyW < 2 || polyH < 2) continue;

            // ── 3. Find principal rectangular axis (calibration) ─────────────
            double rawAngle = 0.0;
            double textAreaW = 0.0;
            double textAreaH = 0.0;
            {
              double sumCos = 0;
              double sumSin = 0;
              for (int i = 0; i < projectedPoly.length - 1; i++) {
                final a = projectedPoly[i];
                final b = projectedPoly[i + 1];
                final dx = b.dx - a.dx;
                final dy = b.dy - a.dy;
                final len = sqrt(dx * dx + dy * dy);
                if (len < 0.1) continue;
                final angle = atan2(dy, dx);
                sumCos += cos(4 * angle) * len;
                sumSin += sin(4 * angle) * len;
              }
              final dominantGrid = atan2(sumSin, sumCos) / 4;

              final ux = cos(dominantGrid);
              final uy = sin(dominantGrid);
              final vx = -uy;
              final vy = ux;

              double minU = double.infinity, maxU = double.negativeInfinity;
              double minV = double.infinity, maxV = double.negativeInfinity;
              for (final pp in projectedPoly) {
                final u = pp.dx * ux + pp.dy * uy;
                final v = pp.dx * vx + pp.dy * vy;
                if (u < minU) minU = u;
                if (u > maxU) maxU = u;
                if (v < minV) minV = v;
                if (v > maxV) maxV = v;
              }
              final spanU = maxU - minU;
              final spanV = maxV - minV;

              if (spanU >= spanV) {
                rawAngle = dominantGrid;
                textAreaW = spanU;
                textAreaH = spanV;
              } else {
                rawAngle = dominantGrid + pi / 2;
                textAreaW = spanV;
                textAreaH = spanU;
              }
            }

            // ── 4. Label position ───────────────────────────────────────────
            final centerPt = Offset(
              (pxMinX + pxMaxX) / 2,
              (pxMinY + pxMaxY) / 2,
            );

            // Normalize atan2 [-π, π] → [0°, 180°) for direction-agnostic angle
            double normAngle = rawAngle;
            if (normAngle < 0) normAngle += pi;
            if (normAngle >= pi) normAngle -= pi;
            final double angleDeg = normAngle * 180 / pi;

            // ── 5. Rotation heuristic ────────────────────────────────────────
            final double aspectRatio = textAreaW / textAreaH;
            final bool shouldRotate =
                aspectRatio > 2.0 &&
                ((angleDeg >= 5.0 && angleDeg <= 85.0) ||
                    (angleDeg >= 95.0 && angleDeg <= 175.0));

            // Paint angle: map (90°, 180°) → (-90°, 0°) so text stays upright
            final double paintAngle = normAngle > pi / 2
                ? normAngle - pi
                : normAngle;

            // ── 5. Font size and chars-per-row ───────────────────────────────
            // Effective area depends on whether we decided to rotate
            final double drawW = shouldRotate ? textAreaW : polyW;
            final double drawH = shouldRotate ? textAreaH : polyH;

            // Initial heuristic: try to fit within 1/4 of the height
            final double utilization = roomName.length > 8 ? 0.95 : 0.88;
            var fontSize = (min(drawW, drawH) / 4).clamp(1.8, 6.0);
            var charsPerRow = max(1, (drawW * utilization / fontSize).floor());

            // Avoid trailing single-char lines and vertical overflow
            if (roomName.length > charsPerRow) {
              final total = roomName.length;
              var lineCount = (total / charsPerRow).ceil();

              // Vertical check: if wrapping makes it too tall, shrink font
              if (lineCount * fontSize * 1.1 > drawH) {
                fontSize = (drawH / (lineCount * 1.1)).clamp(1.5, 6.0);
                charsPerRow = max(1, (drawW * utilization / fontSize).floor());
                lineCount = (total / charsPerRow).ceil();
              }

              final perLine = (total / lineCount).ceil();
              final lastLen = total - perLine * (lineCount - 1);
              if (lineCount > 1 && lastLen < (perLine * 0.4).ceil()) {
                final newCpr = (total / (lineCount - 1)).ceil();
                final newFontSize = (drawW * utilization / newCpr).clamp(
                  1.5,
                  6.0,
                );
                if (newFontSize >= 1.8) {
                  fontSize = newFontSize;
                  charsPerRow = newCpr;
                }
              }
            }

            // ── 6. Balanced CJK wrapping helper ─────────────────────────────
            String balancedWrap(String text) {
              if (text.length <= charsPerRow) return text;
              final lines = (text.length / charsPerRow).ceil();
              final perLine = (text.length / lines).ceil();
              final buf = StringBuffer();
              for (int i = 0; i < text.length; i++) {
                if (i > 0 && i % perLine == 0) buf.write('\n');
                buf.write(text[i]);
              }
              return buf.toString();
            }

            // ── 7. Build label text ──────────────────────────────────────────
            String txt;
            if (roomNo.isNotEmpty && roomName.isNotEmpty) {
              if (roomName.contains(roomNo.replaceAll('\u2011', '-'))) {
                txt = balancedWrap(roomName);
              } else {
                txt = '$roomNo\n${balancedWrap(roomName)}';
              }
            } else if (roomName.isNotEmpty) {
              txt = balancedWrap(roomName);
            } else if (roomNo.isNotEmpty) {
              txt = roomNo;
            } else {
              txt = roomId;
            }

            if (txt.isEmpty) continue;

            // ── 8. Layout ────────────────────────────────────────────────────
            final tp = TextPainter(
              text: TextSpan(
                text: txt,
                style: TextStyle(
                  color: const Color(0xFF334E68),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
            )..layout(maxWidth: textAreaW);

            // ── 9. Paint (with optional rotation) ────────────────────────────
            canvas.save();
            canvas.clipRect(Rect.fromLTRB(pxMinX, pxMinY, pxMaxX, pxMaxY));
            if (shouldRotate) {
              canvas.translate(centerPt.dx, centerPt.dy);
              canvas.rotate(paintAngle);
              tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
            } else {
              tp.paint(
                canvas,
                centerPt - Offset(tp.width / 2, tp.height / 2),
              );
            }
            canvas.restore();
          }
        }
      }
    }

    draw(buildings, pFillB, pStrokeB);
    draw(rooms, pFillR, pStrokeR, label: true);
  }

  Offset _project(VectorPoint p, Size size) {
    // p is already in Web Mercator EPSG:3857 because of campus_map_service change
    final x = (p.x - bbox.minX) / (bbox.maxX - bbox.minX) * size.width;
    final y = (1.0 - (p.y - bbox.minY) / (bbox.maxY - bbox.minY)) * size.height;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.rooms != rooms || old.buildings != buildings;
}
