import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/map/campus_map_parser.dart';

void main() {
  group('parseCampusMapLayers', () {
    test('reads supported layers with and without XML namespace prefixes', () {
      const xml = '''
        <wfs:WFS_Capabilities xmlns:wfs="urn:wfs" xmlns:g="urn:gis">
          <wfs:FeatureTypeList>
            <wfs:FeatureType><wfs:Name>gis_room:A1T_1F</wfs:Name></wfs:FeatureType>
            <g:FeatureType><g:Name>gis_room:A1T_1M</g:Name></g:FeatureType>
            <FeatureType><Name>gis_room:B2_R2</Name></FeatureType>
            <wfs:FeatureType><wfs:Name>gis:unrelated</wfs:Name></wfs:FeatureType>
          </wfs:FeatureTypeList>
        </wfs:WFS_Capabilities>
      ''';

      expect(parseCampusMapLayers(xml), [
        (name: 'gis_room:A1T_1F', buildingCode: 'A1T', floor: '1F'),
        (name: 'gis_room:A1T_1M', buildingCode: 'A1T', floor: '1M'),
        (name: 'gis_room:B2_R2', buildingCode: 'B2', floor: 'R2'),
      ]);
    });

    test('throws when the capabilities document has no indoor layers', () {
      expect(
        () => parseCampusMapLayers(
          '<Capabilities><FeatureTypeList/></Capabilities>',
        ),
        throwsFormatException,
      );
    });
  });

  group('parseCampusMapRooms', () {
    test('parses prefixed and unprefixed ids, preserving Polygon holes and MultiPolygon parts', () {
      final rooms = parseCampusMapRooms(
        _featureCollection([
          _feature(
            id: 'gis_room:A1T_1F.101',
            geometry: _polygonGeometry([
              _ring(0, 0),
              _ring(1, 1),
            ]),
          ),
          _feature(
            id: 'A1T_1M.102',
            geometry: _multiPolygonGeometry([
              [_ring(2, 2), _ring(3, 3)],
              [_ring(4, 4)],
            ]),
          ),
        ]),
      );

      expect(rooms, hasLength(2));
      expect(rooms[0].id, 'A1T_1F.101');
      expect(rooms[0].layerName, 'gis_room:A1T_1F');
      expect(rooms[0].polygons, hasLength(1));
      expect(rooms[0].polygons.single, hasLength(2));
      expect(rooms[0].polygons.single[1], hasLength(5));
      expect(rooms[1].id, 'A1T_1M.102');
      expect(rooms[1].layerName, 'gis_room:A1T_1M');
      expect(rooms[1].polygons, hasLength(2));
      expect(rooms[1].polygons.map((polygon) => polygon.length), [2, 1]);
    });

    test('keeps searchable metadata when geometry is absent', () {
      final room = parseCampusMapRooms(
        _featureCollection([
          _feature(
            id: 'A1T_2F.201',
            geometry: null,
            properties: {
              'room_name': '測試空間',
              'room_name_en': 'Sample Space',
              'class_num': '201',
            },
          ),
        ]),
      ).single;

      expect(room.nameZh, '測試空間');
      expect(room.nameEn, 'Sample Space');
      expect(room.number, '201');
      expect(room.polygons, isEmpty);
    });

    test('rejects invalid coordinate values', () {
      final invalid = _ring(0, 0)..[1] = [181, 0];
      final source = _featureCollection([
        _feature(id: 'A1T_1F.101', geometry: _polygonGeometry([invalid])),
      ]);

      expect(() => parseCampusMapRooms(source), throwsFormatException);
    });

    test('rejects unclosed rings', () {
      final unclosed = _ring(0, 0)..removeLast();
      final source = _featureCollection([
        _feature(id: 'A1T_1F.101', geometry: _polygonGeometry([unclosed])),
      ]);

      expect(() => parseCampusMapRooms(source), throwsFormatException);
    });

    test(
      'rejects polygons with no exterior ring instead of returning empty rings',
      () {
        final source = _featureCollection([
          _feature(id: 'A1T_1F.101', geometry: _polygonGeometry([])),
        ]);

        expect(() => parseCampusMapRooms(source), throwsFormatException);
      },
    );
  });

  test('parses building outlines and retains uncoded feature ids', () {
    final buildings = parseCampusMapBuildings(
      _featureCollection([
        _feature(
          id: 'feature.1',
          properties: {'build_name': 'Test Hall'},
          geometry: _polygonGeometry([_ring(0, 0), _ring(1, 1)]),
        ),
      ]),
    );

    expect(buildings.single.id, 'feature.1');
    expect(buildings.single.code, isEmpty);
    expect(buildings.single.name, 'Test Hall');
    expect(buildings.single.polygons.single, hasLength(2));
  });
}

String _featureCollection(List<Map<String, dynamic>> features) =>
    jsonEncode({'type': 'FeatureCollection', 'features': features});

Map<String, dynamic> _feature({
  required String id,
  required dynamic geometry,
  Map<String, dynamic> properties = const {},
}) => {
  'type': 'Feature',
  'id': id,
  'properties': properties,
  'geometry': geometry,
};

Map<String, dynamic> _polygonGeometry(List<List<List<num>>> rings) => {
  'type': 'Polygon',
  'coordinates': rings,
};

Map<String, dynamic> _multiPolygonGeometry(
  List<List<List<List<num>>>> polygons,
) => {
  'type': 'MultiPolygon',
  'coordinates': polygons,
};

List<List<num>> _ring(num x, num y) => [
  [x, y],
  [x + 1, y],
  [x + 1, y + 1],
  [x, y + 1],
  [x, y],
];
