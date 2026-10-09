import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/screens/main/map/campus_map_room_labels.dart';

// Tests for the room label layout in campus_map_room_labels.dart.
//
// Labels are drawn straight onto the map canvas, so there is no widget to find
// and tap. The layout tests below feed projected room outlines to
// layoutCampusMapRoomLabel and check that the text stays inside the room. The
// last tests paint the label widget onto a recording canvas to check zoom
// behavior, which would otherwise only be visible by eye on a device.
void main() {
  testWidgets('small rectangular room centers a label with number and name', (
    tester,
  ) async {
    final layout = layoutCampusMapRoomLabel(
      rings: [
        _ring(const [
          Offset(0, 0),
          Offset(80, 0),
          Offset(80, 32),
          Offset(0, 32),
        ]),
      ],
      number: '101',
      name: 'Lab',
      color: const Color(0xff222222),
    );
    addTearDown(layout.textPainter.dispose);

    expect(layout.center, const Offset(40, 16));
    expect(layout.angle, 0);
    expect(layout.textPainter.text!.toPlainText(), contains('101'));
    expect(layout.textPainter.text!.toPlainText(), contains('Lab'));
  });

  testWidgets('narrow rotated room fits and wraps its label', (tester) async {
    const width = 36.0;
    const length = 120.0;
    final angle = math.pi / 6;
    Offset rotated(double x, double y) => Offset(
      x * math.cos(angle) - y * math.sin(angle),
      x * math.sin(angle) + y * math.cos(angle),
    );
    final layout = layoutCampusMapRoomLabel(
      rings: [
        _ring([
          rotated(0, 0),
          rotated(length, 0),
          rotated(length, width),
          rotated(0, width),
        ]),
      ],
      number: 'A-123',
      name: 'Long classroom name',
      color: const Color(0xff222222),
    );
    addTearDown(layout.textPainter.dispose);

    final label = layout.textPainter.text!.toPlainText();
    expect(layout.angle.abs(), greaterThan(0.2));
    expect(label, contains('\n'));
    expect(label.replaceAll('\n', ''), contains('A-123'));
    expect(label.replaceAll('\n', ''), contains('Long classroom name'));
    expect(layout.clipPath.contains(layout.center), isTrue);
    expect(layout.textPainter.width, lessThanOrEqualTo(length * 0.88));
    expect(layout.textPainter.height, lessThanOrEqualTo(width * 0.88));
  });

  testWidgets('label center falls inside the room around a hole or concavity', (
    tester,
  ) async {
    final withHole = layoutCampusMapRoomLabel(
      rings: [
        _ring(const [
          Offset(0, 0),
          Offset(100, 0),
          Offset(100, 100),
          Offset(0, 100),
        ]),
        _ring(const [
          Offset(40, 40),
          Offset(60, 40),
          Offset(60, 60),
          Offset(40, 60),
        ]),
      ],
      number: 'H1',
      name: 'Hall',
      color: const Color(0xff222222),
    );
    final concave = layoutCampusMapRoomLabel(
      rings: [
        _ring(const [
          Offset(0, 0),
          Offset(100, 0),
          Offset(100, 30),
          Offset(30, 30),
          Offset(30, 100),
          Offset(0, 100),
        ]),
      ],
      number: 'C1',
      name: 'Corner',
      color: const Color(0xff222222),
    );
    addTearDown(withHole.textPainter.dispose);
    addTearDown(concave.textPainter.dispose);

    expect(withHole.center, isNot(const Offset(50, 50)));
    expect(withHole.clipPath.contains(withHole.center), isTrue);
    expect(concave.center, isNot(const Offset(50, 50)));
    expect(concave.clipPath.contains(concave.center), isTrue);
  });

  testWidgets('L-shaped room keeps long label horizontal and inside its arms', (
    tester,
  ) async {
    final ring = _ring(const [
      Offset(0, 0),
      Offset(120, 0),
      Offset(120, 36),
      Offset(36, 36),
      Offset(36, 120),
      Offset(0, 120),
    ]);
    final layout = layoutCampusMapRoomLabel(
      rings: [ring],
      number: 'A-123456789',
      name: '超長的教室名稱填滿可用空間並保持完整可讀',
      color: const Color(0xff222222),
    );
    addTearDown(layout.textPainter.dispose);

    final label = layout.textPainter.text!.toPlainText().replaceAll(
      RegExp(r'\s+'),
      '',
    );
    expect(layout.angle, 0);
    expect(label, contains('A-123456789'));
    expect(label, contains('超長的教室名稱填滿可用空間並保持完整可讀'));

    final textBounds = Rect.fromCenter(
      center: layout.center,
      width: layout.textPainter.width,
      height: layout.textPainter.height,
    );
    _expectTextBoundsInside(textBounds, layout.clipPath);
  });

  testWidgets('long CJK labels keep their paragraph across fractional zooms', (
    tester,
  ) async {
    // Regression test: long names used to re-wrap at every fractional zoom
    // level and flicker while pinching. The label must be laid out once at a
    // fixed zoom, then only scaled and translated as the camera moves.
    final controller = MapController();
    final room = _longRoom();
    await tester.pumpWidget(_labelMap(controller, [room]));

    final first = _recordLabel(tester);
    expect(first.paragraph.height, greaterThan(20));
    final firstCamera = controller.camera;
    final firstScale = firstCamera.getZoomScale(firstCamera.zoom, 20);
    expect(first.scale, closeTo(firstScale, 1e-9));
    _expectOffsetClose(
      first.translation,
      _screenTranslation(firstCamera, room.polygons.single.rings.first.first),
    );

    for (final zoom in [19.63, 20.27, 19.81, 20.0]) {
      controller.move(const LatLng(25, 121.5), zoom);
      await tester.pump();
      final frame = _recordLabel(tester);
      expect(frame.paragraph, same(first.paragraph), reason: 'zoom $zoom');
      expect(frame.paragraph.height, first.paragraph.height);
      final camera = controller.camera;
      expect(
        frame.scale,
        closeTo(camera.getZoomScale(camera.zoom, 20), 1e-9),
      );
      _expectOffsetClose(
        frame.translation,
        _screenTranslation(camera, room.polygons.single.rings.first.first),
      );
    }

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('renaming a room or scaling text rebuilds the cached layout', (
    tester,
  ) async {
    // Layouts are cached per polygon, so a stale cache would keep showing the
    // old wrapping after the room name or the user's font size changes.
    final controller = MapController();
    await tester.pumpWidget(_labelMap(controller, [_longRoom()]));
    final original = _recordLabel(tester).paragraph;

    final renamed = [_longRoom(name: '超長的教室名稱用來確認文字更新後會重新排版')];
    await tester.pumpWidget(_labelMap(controller, renamed));
    final renamedParagraph = _recordLabel(tester).paragraph;
    expect(renamedParagraph, isNot(same(original)));

    await tester.pumpWidget(
      _labelMap(controller, renamed, textScaler: TextScaler.linear(1.5)),
    );
    expect(_recordLabel(tester).paragraph, isNot(same(renamedParagraph)));

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}

List<Offset> _ring(List<Offset> points) => [...points, points.first];

Widget _labelMap(
  MapController controller,
  List<CampusMapRoom> rooms, {
  TextScaler textScaler = TextScaler.noScaling,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(textScaler: textScaler),
    child: SizedBox(
      width: 800,
      height: 600,
      child: FlutterMap(
        mapController: controller,
        options: const MapOptions(
          initialCenter: LatLng(25, 121.5),
          initialZoom: 20,
          minZoom: 15,
          maxZoom: 22,
        ),
        children: [CampusMapRoomLabels(rooms: rooms)],
      ),
    ),
  ),
);

/// Paints the label widget on a recording canvas and returns the single
/// paragraph it drew, plus the scale and translation applied to the canvas.
({ui.Paragraph paragraph, double scale, Offset translation}) _recordLabel(
  WidgetTester tester,
) {
  final customPaintFinder = find.descendant(
    of: find.byType(CampusMapRoomLabels),
    matching: find.byType(CustomPaint),
  );
  final customPaint = tester.widget<CustomPaint>(customPaintFinder);
  final canvas = TestRecordingCanvas();
  customPaint.painter!.paint(canvas, tester.getSize(customPaintFinder));
  final invocations = canvas.invocations.map((record) => record.invocation);
  final paragraph = invocations
      .where((call) => call.memberName == #drawParagraph)
      .map((call) => call.positionalArguments.first as ui.Paragraph)
      .single;
  final scale = invocations
      .where((call) => call.memberName == #scale)
      .map((call) => call.positionalArguments.first as double)
      .single;
  final translation = invocations
      .where((call) => call.memberName == #translate)
      .map(
        (call) => Offset(
          call.positionalArguments[0] as double,
          call.positionalArguments[1] as double,
        ),
      )
      .first;
  return (paragraph: paragraph, scale: scale, translation: translation);
}

Offset _screenTranslation(MapCamera camera, CampusMapPoint point) {
  final projected = camera.projectAtZoom(
    LatLng(point.latitude, point.longitude),
  );
  return projected - camera.pixelOrigin;
}

void _expectOffsetClose(Offset actual, Offset expected) {
  expect(actual.dx, closeTo(expected.dx, 1e-6));
  expect(actual.dy, closeTo(expected.dy, 1e-6));
}

void _expectTextBoundsInside(Rect bounds, ui.Path room) {
  // Dense sampling detects clipped text crossing an L cutout or room hole.
  const samplesPerSide = 64;
  for (var x = 0; x < samplesPerSide; x++) {
    for (var y = 0; y < samplesPerSide; y++) {
      final point = Offset(
        bounds.left + bounds.width * (x + 0.5) / samplesPerSide,
        bounds.top + bounds.height * (y + 0.5) / samplesPerSide,
      );
      expect(
        room.contains(point),
        isTrue,
        reason: 'text sample $point must be inside the room outline',
      );
    }
  }
}

CampusMapRoom _longRoom({String? name}) {
  const center = LatLng(25, 121.5);
  const halfWidth = 0.00013;
  const halfHeight = 0.000025;
  final polygon = CampusMapPolygon([
    _geoRing([
      (
        longitude: center.longitude - halfWidth,
        latitude: center.latitude - halfHeight,
      ),
      (
        longitude: center.longitude + halfWidth,
        latitude: center.latitude - halfHeight,
      ),
      (
        longitude: center.longitude + halfWidth,
        latitude: center.latitude + halfHeight,
      ),
      (
        longitude: center.longitude - halfWidth,
        latitude: center.latitude + halfHeight,
      ),
    ]),
  ]);
  return CampusMapRoom(
    id: 'A1T_1F.101',
    buildingCode: 'A1T',
    buildingName: 'Alpha Hall',
    floor: const CampusMapFloor(layerName: 'gis_room:A1T_1F', code: '1F'),
    nameZh: name ?? '這是一個非常長的教室名稱用來測試縮放時穩定換行效果',
    nameEn: name ?? '這是一個非常長的教室名稱用來測試縮放時穩定換行效果',
    number: 'A-123',
    polygons: [polygon],
  );
}

List<CampusMapPoint> _geoRing(List<CampusMapPoint> points) => [
  ...points,
  points.first,
];
