import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/portal/ntut_portal_service.dart';
import 'package:tattoo/services/portal/portal_service.dart';

void main() {
  const shortDeadline = Duration(milliseconds: 500);
  const testTimeout = Timeout(Duration(seconds: 5));

  group('iSchool Plus SSO deadline', () {
    test('cancels a stalled form request', () async {
      final requestStarted = Completer<CancelToken>();
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              requestStarted.complete(options.cancelToken!);
              handler.reject(await options.cancelToken!.whenCancel);
            },
          ),
        );
      final service = NtutPortalService(
        dio: dio,
        iSchoolSsoTimeout: shortDeadline,
      );

      final result = expectLater(
        service.sso(PortalServiceCode.iSchoolPlusService.code),
        throwsA(_cancelledDioException),
      );
      final cancelToken = await requestStarted.future;
      await result;

      expect(cancelToken.isCancelled, isTrue);
    }, timeout: testTimeout);

    test('cancels a stalled form submission', () async {
      final submissionStarted = Completer<CancelToken>();
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              if (options.path == 'ssoIndex.do') {
                handler.resolve(_ssoFormResponse(options));
                return;
              }
              submissionStarted.complete(options.cancelToken!);
              handler.reject(await options.cancelToken!.whenCancel);
            },
          ),
        );
      final service = NtutPortalService(
        dio: dio,
        iSchoolSsoTimeout: shortDeadline,
      );

      final result = expectLater(
        service.sso(PortalServiceCode.iSchoolPlusService.code),
        throwsA(_cancelledDioException),
      );
      final cancelToken = await submissionStarted.future;
      await result;

      expect(cancelToken.isCancelled, isTrue);
    }, timeout: testTimeout);

    test('cancels a stalled redirect before retrying', () async {
      final redirectStarted = Completer<CancelToken>();
      var activeRedirects = 0;
      var maxActiveRedirects = 0;
      var stallRedirect = true;
      final requestTokens = <CancelToken>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              requestTokens.add(options.cancelToken!);
              if (options.path == 'ssoIndex.do') {
                handler.resolve(_ssoFormResponse(options));
                return;
              }
              if (options.path == 'oauth2Server.do') {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 302,
                    headers: Headers.fromMap({
                      'location': [
                        'https://ischool.ntut.edu.tw/login',
                      ],
                    }),
                  ),
                );
                return;
              }

              activeRedirects++;
              if (activeRedirects > maxActiveRedirects) {
                maxActiveRedirects = activeRedirects;
              }
              if (stallRedirect) {
                stallRedirect = false;
                redirectStarted.complete(options.cancelToken!);
                final error = await options.cancelToken!.whenCancel;
                activeRedirects--;
                handler.reject(error);
                return;
              }
              activeRedirects--;
              handler.resolve(
                Response(requestOptions: options, statusCode: 200),
              );
            },
          ),
        );
      final service = NtutPortalService(
        dio: dio,
        iSchoolSsoTimeout: shortDeadline,
      );

      final firstAttempt = expectLater(
        service.sso(PortalServiceCode.iSchoolPlusService.code),
        throwsA(_cancelledDioException),
      );
      final firstToken = await redirectStarted.future;
      await firstAttempt;
      expect(firstToken.isCancelled, isTrue);
      expect(requestTokens, hasLength(3));
      expect(
        requestTokens.every((token) => identical(token, firstToken)),
        isTrue,
      );

      requestTokens.clear();
      await service.sso(PortalServiceCode.iSchoolPlusService.code);

      expect(requestTokens.toSet(), hasLength(1));
      expect(maxActiveRedirects, 1);
      expect(activeRedirects, 0);
    }, timeout: testTimeout);

    test(
      'timed-out queued work sends no request and a retry can start',
      () async {
        final firstRequestStarted = Completer<void>();
        final releaseFirstRequest = Completer<void>();
        final requests = <({String path, String? serviceCode})>[];
        var holdFirstRequest = true;
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) async {
                requests.add((
                  path: options.path,
                  serviceCode: options.queryParameters['apOu'] as String?,
                ));
                if (holdFirstRequest) {
                  holdFirstRequest = false;
                  firstRequestStarted.complete();
                  await releaseFirstRequest.future;
                }
                handler.resolve(
                  options.path == 'ssoIndex.do'
                      ? _ssoFormResponse(options)
                      : Response(requestOptions: options, statusCode: 200),
                );
              },
            ),
          );
        final service = NtutPortalService(
          dio: dio,
          iSchoolSsoTimeout: shortDeadline,
        );

        final lockHolder = service.sso(PortalServiceCode.courseService.code);
        await firstRequestStarted.future;

        await expectLater(
          service.sso(PortalServiceCode.iSchoolPlusService.code),
          throwsA(_cancelledDioException),
        );
        expect(
          requests.where(
            (request) =>
                request.serviceCode ==
                PortalServiceCode.iSchoolPlusService.code,
          ),
          isEmpty,
        );

        final retry = service.sso(PortalServiceCode.iSchoolPlusService.code);
        releaseFirstRequest.complete();
        await lockHolder;
        await retry;

        expect(
          requests
              .where(
                (request) =>
                    request.serviceCode ==
                    PortalServiceCode.iSchoolPlusService.code,
              )
              .length,
          1,
        );
      },
      timeout: testTimeout,
    );

    test('does not apply the deadline to other SSO targets', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              await Future<void>.delayed(shortDeadline * 2);
              handler.resolve(
                options.path == 'ssoIndex.do'
                    ? _ssoFormResponse(options)
                    : Response(requestOptions: options, statusCode: 200),
              );
            },
          ),
        );
      final service = NtutPortalService(
        dio: dio,
        iSchoolSsoTimeout: shortDeadline,
      );

      await service.sso(PortalServiceCode.courseService.code);
    }, timeout: testTimeout);

    test('allows a normal iSchool Plus SSO to complete', () async {
      final requests = <RequestOptions>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add(options);
              handler.resolve(
                options.path == 'ssoIndex.do'
                    ? _ssoFormResponse(options)
                    : Response(requestOptions: options, statusCode: 200),
              );
            },
          ),
        );
      final service = NtutPortalService(
        dio: dio,
        iSchoolSsoTimeout: shortDeadline,
      );

      await service.sso(PortalServiceCode.iSchoolPlusService.code);

      expect(requests.map((request) => request.path), [
        'ssoIndex.do',
        'oauth2Server.do',
      ]);
      expect(requests.every((request) => request.cancelToken != null), isTrue);
    }, timeout: testTimeout);

    test('follows an adapter-backed 302 as GET', () async {
      final adapter = _SsoRedirectAdapter(statusCode: 302);
      final dio = Dio()..httpClientAdapter = adapter;
      final service = NtutPortalService(
        dio: dio,
        iSchoolSsoTimeout: shortDeadline,
      );

      await service.sso(PortalServiceCode.iSchoolPlusService.code);

      expect(adapter.requests.map((request) => request.method), [
        'GET',
        'POST',
        'GET',
      ]);
    }, timeout: testTimeout);

    test('preserves POST for an adapter-backed 307', () async {
      final adapter = _SsoRedirectAdapter(statusCode: 307);
      final dio = Dio()..httpClientAdapter = adapter;
      final service = NtutPortalService(
        dio: dio,
        iSchoolSsoTimeout: shortDeadline,
      );

      await service.sso(PortalServiceCode.iSchoolPlusService.code);

      expect(adapter.requests.map((request) => request.method), [
        'GET',
        'POST',
        'POST',
      ]);
      expect(adapter.requests.last.data, isA<Map<String, dynamic>>());
    }, timeout: testTimeout);
  });
}

final _cancelledDioException = isA<DioException>().having(
  (error) => error.type,
  'type',
  DioExceptionType.cancel,
);

Response<String> _ssoFormResponse(RequestOptions options) {
  return Response(
    requestOptions: options,
    statusCode: 200,
    data: '<form name="ssoForm" action="oauth2Server.do"></form>',
  );
}

class _SsoRedirectAdapter implements HttpClientAdapter {
  _SsoRedirectAdapter({required this.statusCode});

  final int statusCode;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return switch (options.uri.path) {
      '/ssoIndex.do' => ResponseBody.fromString(
        '<form name="ssoForm" action="oauth2Server.do"></form>',
        200,
      ),
      '/oauth2Server.do' => ResponseBody.fromString(
        '',
        statusCode,
        headers: {
          'location': ['https://ischool.ntut.edu.tw/login'],
        },
      ),
      '/login' => ResponseBody.fromString('', 200),
      _ => throw StateError('Unexpected request: ${options.uri}'),
    };
  }

  @override
  void close({bool force = false}) {}
}
