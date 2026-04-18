import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void main() async {
  final dio = Dio();
  (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (client) {
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  };

  final r1 = await dio.get(
    'https://geoserver.oga.ntut.edu.tw/ows',
    queryParameters: {
      'service': 'WFS',
      'version': '1.0.0',
      'request': 'GetFeature',
      'typeName': 'gis_room:A1T_1F,gis_room:A1T_2F',
      'outputFormat': 'application/json',
    },
  );
  print(r1.data['features'].length);

  final r2 = await dio.get(
    'https://geoserver.oga.ntut.edu.tw/ows',
    queryParameters: {
      'service': 'WFS',
      'version': '1.1.0',
      'request': 'GetFeature',
      'typeName': 'gis_room:A1T_1F,gis_room:A1T_2F',
      'outputFormat': 'application/json',
    },
  );
  print(r2.data['features'].length);
}
