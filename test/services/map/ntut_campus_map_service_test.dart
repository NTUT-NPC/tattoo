import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/map/ntut_campus_map_service.dart';

void main() {
  group('NtutCampusMapService', () {
    test('requests a single floor without metadata-only properties', () async {
      final adapter = _GeoServerAdapter();
      final service = NtutCampusMapService(
        dio: Dio()..httpClientAdapter = adapter,
      );

      final rooms = await service.getRooms('gis_room:A1T_1F');

      expect(rooms, isEmpty);
      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.single;
      expect(request.queryParameters['request'], 'GetFeature');
      expect(request.queryParameters['typeName'], 'gis_room:A1T_1F');
      expect(request.queryParameters.containsKey('propertyName'), isFalse);
    });

    test(
      'treats a known unavailable backing layer as an empty floor',
      () async {
        final adapter = _GeoServerAdapter(
          body: _missingSchema('AD_R1'),
        );
        final service = NtutCampusMapService(
          dio: Dio()..httpClientAdapter = adapter,
        );

        expect(await service.getRooms('gis_room:AD_R1'), isEmpty);
        expect(adapter.requests, hasLength(1));
      },
    );

    test(
      'removes one unavailable layer and retries the remaining index batch',
      () async {
        final adapter = _GeoServerAdapter(
          bodyFor: (request) =>
              (request.queryParameters['typeName'] as String).contains('AD_R1')
              ? _missingSchema('AD_R1')
              : '{"type":"FeatureCollection","features":[]}',
        );
        final service = NtutCampusMapService(
          dio: Dio()..httpClientAdapter = adapter,
        );

        expect(
          await service.getRoomIndex([
            'gis_room:AD_R1',
            'gis_room:A1T_1F',
            'gis_room:B2_2F',
          ]),
          isEmpty,
        );

        expect(adapter.requests, hasLength(2));
        expect(
          adapter.requests.first.queryParameters['typeName'],
          'gis_room:AD_R1,gis_room:A1T_1F,gis_room:B2_2F',
        );
        expect(
          adapter.requests.last.queryParameters['typeName'],
          'gis_room:A1T_1F,gis_room:B2_2F',
        );
        expect(
          adapter.requests.every(
            (request) =>
                request.queryParameters['propertyName'] ==
                'room_name,room_name_en,class_num',
          ),
          isTrue,
        );
      },
    );

    test('does not swallow unrelated WFS exceptions', () async {
      final body = _wfsException('The request could not be completed.');
      final floorService = NtutCampusMapService(
        dio: Dio()..httpClientAdapter = _GeoServerAdapter(body: body),
      );
      final indexService = NtutCampusMapService(
        dio: Dio()
          ..httpClientAdapter = _GeoServerAdapter(
            bodyFor: (request) =>
                (request.queryParameters['typeName'] as String).contains(
                  'AD_R1',
                )
                ? body
                : '{"type":"FeatureCollection","features":[]}',
          ),
      );

      await expectLater(
        floorService.getRooms('gis_room:AD_R1'),
        throwsFormatException,
      );
      await expectLater(
        indexService.getRoomIndex(['gis_room:AD_R1', 'gis_room:A1T_1F']),
        throwsFormatException,
      );
    });

    test(
      'fetches metadata-only room index in sequential batches of 25',
      () async {
        final adapter = _GeoServerAdapter();
        final service = NtutCampusMapService(
          dio: Dio()..httpClientAdapter = adapter,
        );
        final layers = [for (var i = 1; i <= 26; i++) 'gis_room:A1T_${i}F'];

        final rooms = await service.getRoomIndex(layers);

        expect(rooms, isEmpty);
        expect(adapter.requests, hasLength(2));
        expect(
          adapter.requests.map(
            (request) => request.queryParameters['typeName'],
          ),
          [layers.take(25).join(','), layers.last],
        );
        expect(
          adapter.requests.map(
            (request) => request.queryParameters['propertyName'],
          ),
          everyElement('room_name,room_name_en,class_num'),
        );
        expect(
          adapter.requests.every(
            (request) => request.queryParameters['SRSNAME'] == 'EPSG:4326',
          ),
          isTrue,
        );
      },
    );

    test('propagates HTTP and GeoJSON parsing errors', () async {
      final httpAdapter = _GeoServerAdapter(statusCode: 503);
      final httpService = NtutCampusMapService(
        dio: Dio()..httpClientAdapter = httpAdapter,
      );
      await expectLater(
        httpService.getRooms('gis_room:A1T_1F'),
        throwsA(isA<DioException>()),
      );

      final parserAdapter = _GeoServerAdapter(body: 'not GeoJSON');
      final parserService = NtutCampusMapService(
        dio: Dio()..httpClientAdapter = parserAdapter,
      );
      await expectLater(
        parserService.getRooms('gis_room:A1T_1F'),
        throwsFormatException,
      );
    });
  });
}

class _GeoServerAdapter implements HttpClientAdapter {
  _GeoServerAdapter({
    this.statusCode = 200,
    this.body = '{"type":"FeatureCollection","features":[]}',
    this.bodyFor,
  });

  final int statusCode;
  final String body;
  final String Function(RequestOptions request)? bodyFor;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(bodyFor?.call(options) ?? body, statusCode);
  }

  @override
  void close({bool force = false}) {}
}

String _missingSchema(String schema) =>
    _wfsException("Schema '$schema' does not exist.");

String _wfsException(String message) =>
    '''
  <ows:ExceptionReport xmlns:ows="http://www.opengis.net/ows">
    <ows:Exception><ows:ExceptionText>$message</ows:ExceptionText></ows:Exception>
  </ows:ExceptionReport>
''';
