import 'package:tattoo/services/map/campus_map_service.dart';

/// A small local campus map for demo sessions and deterministic UI tests.
class MockCampusMapService implements CampusMapService {
  @override
  Future<List<CampusMapBuildingDto>> getBuildings() async => [
    (
      id: 'demo-building',
      code: 'A1T',
      name: '第一教學大樓',
      polygons: _rectangle(121.53365, 25.04325, 0.0002, 0.00015),
    ),
  ];

  @override
  Future<List<CampusMapLayerDto>> getLayers() async => [
    for (final floor in ['1F', '2F'])
      (name: 'gis_room:A1T_$floor', buildingCode: 'A1T', floor: floor),
  ];

  @override
  Future<List<CampusMapRoomDto>> getRooms(String layerName) async => [
    (
      id: '${layerName.split(':').last}.1',
      layerName: layerName,
      nameZh: '教室',
      nameEn: 'Classroom',
      number: layerName.endsWith('1F') ? '101' : '201',
      polygons: _rectangle(121.53365, 25.04325, 0.0002, 0.00015),
    ),
  ];

  @override
  Future<List<CampusMapRoomDto>> getRoomIndex(List<String> layerNames) async =>
      [
        for (final name in layerNames)
          for (final room in await getRooms(name))
            (
              id: room.id,
              layerName: room.layerName,
              nameZh: room.nameZh,
              nameEn: room.nameEn,
              number: room.number,
              polygons: const [],
            ),
      ];

  CampusMapGeometryDto _rectangle(
    double lon,
    double lat,
    double width,
    double height,
  ) => [
    [
      [
        (longitude: lon, latitude: lat),
        (longitude: lon + width, latitude: lat),
        (longitude: lon + width, latitude: lat + height),
        (longitude: lon, latitude: lat + height),
        (longitude: lon, latitude: lat),
      ],
    ],
  ];
}
