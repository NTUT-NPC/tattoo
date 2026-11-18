import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tattoo/utils/dio_http_client.dart';
import 'package:tattoo/utils/http.dart';

void main() {
  test(
    'uses shared interceptors and preserves tile bytes and cache headers',
    () async {
      final bytes = [137, 80, 78, 71, 255, 0];
      final adapter = _Adapter(
        respond: (_, _) async => ResponseBody.fromBytes(
          bytes,
          200,
          headers: {
            'content-type': ['image/png'],
            'cache-control': ['max-age=3600'],
            'etag': ['"tile-v1"'],
          },
        ),
      );
      final client = DioHttpClient(createDio()..httpClientAdapter = adapter);
      addTearDown(client.close);
      final request =
          http.Request('GET', Uri.parse('http://tiles.example/3/4/5.png'))
            ..headers.addAll({
              'User-Agent': 'flutter_map (club.ntut.tattoo)',
              'If-None-Match': '"tile-v0"',
            });

      final response = await client.send(request);

      expect(await response.stream.toBytes(), bytes);
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], 'image/png');
      expect(response.headers['cache-control'], 'max-age=3600');
      expect(response.headers['etag'], '"tile-v1"');
      final sent = adapter.requests.single;
      expect(sent.uri.scheme, 'https');
      expect(sent.method, 'GET');
      expect(sent.headers['User-Agent'], 'flutter_map (club.ntut.tattoo)');
      expect(sent.headers['If-None-Match'], '"tile-v0"');
      expect(sent.headers['X-Client'], isNotEmpty);
    },
  );

  test('preserves 304 responses for cached tile revalidation', () async {
    final adapter = _Adapter(
      respond: (_, _) async => ResponseBody.fromBytes(
        [],
        304,
        headers: {
          'cache-control': ['max-age=7200'],
        },
      ),
    );
    final client = DioHttpClient(createDio()..httpClientAdapter = adapter);
    addTearDown(client.close);

    final response = await client.get(
      Uri.parse('https://tiles.example/tile.png'),
    );

    expect(response.statusCode, 304);
    expect(response.bodyBytes, isEmpty);
    expect(response.headers['cache-control'], 'max-age=7200');
  });

  test('converts HTTP failures to client exceptions', () async {
    final adapter = _Adapter(
      respond: (_, _) async => ResponseBody.fromBytes([], 503),
    );
    final client = DioHttpClient(createDio()..httpClientAdapter = adapter);
    addTearDown(client.close);

    await expectLater(
      client.get(Uri.parse('https://tiles.example/tile.png')),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('converts timeouts to client exceptions', () async {
    final adapter = _Adapter(
      respond: (options, _) async => throw DioException(
        requestOptions: options,
        type: .receiveTimeout,
        message: 'Tile request timed out',
      ),
    );
    final client = DioHttpClient(createDio()..httpClientAdapter = adapter);
    addTearDown(client.close);

    await expectLater(
      client.get(Uri.parse('https://tiles.example/tile.png')),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('aborts an obsolete tile request through Dio cancellation', () async {
    final started = Completer<void>();
    final adapter = _Adapter(
      respond: (_, cancelled) async {
        started.complete();
        await cancelled;
        return ResponseBody.fromBytes([], 200);
      },
    );
    final client = DioHttpClient(createDio()..httpClientAdapter = adapter);
    addTearDown(client.close);
    final abort = Completer<void>();
    final result = client.send(
      http.AbortableRequest(
        'GET',
        Uri.parse('https://tiles.example/tile.png'),
        abortTrigger: abort.future,
      ),
    );
    final assertion = expectLater(
      result,
      throwsA(isA<http.RequestAbortedException>()),
    );

    await started.future;
    abort.complete();

    await assertion;
    expect(adapter.requests, hasLength(1));
  });

  test('honors an abort that completed before sending', () async {
    final adapter = _Adapter();
    final client = DioHttpClient(createDio()..httpClientAdapter = adapter);
    addTearDown(client.close);

    await expectLater(
      client.send(
        http.AbortableRequest(
          'GET',
          Uri.parse('https://tiles.example/tile.png'),
          abortTrigger: Future.value(),
        ),
      ),
      throwsA(isA<http.RequestAbortedException>()),
    );
    expect(adapter.requests, isEmpty);
  });

  test('closing the client closes its Dio adapter', () {
    final adapter = _Adapter();
    final client = DioHttpClient(createDio()..httpClientAdapter = adapter);

    client.close();

    expect(adapter.closedForcefully, isTrue);
  });
}

class _Adapter implements HttpClientAdapter {
  _Adapter({this.respond});

  final Future<ResponseBody> Function(RequestOptions, Future<void>?)? respond;
  final requests = <RequestOptions>[];
  bool closedForcefully = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond?.call(options, cancelFuture) ??
        ResponseBody.fromBytes([], 200);
  }

  @override
  void close({bool force = false}) => closedForcefully = force;
}
