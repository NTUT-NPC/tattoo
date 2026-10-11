import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/i_school_plus/ntut_i_school_plus_service.dart';
import 'package:tattoo/utils/http.dart';

void main() {
  test('public availability probe succeeds without authentication', () async {
    late RequestOptions request;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            request = options;
            handler.resolve(Response(requestOptions: options, statusCode: 200));
          },
        ),
      );

    await NtutISchoolPlusService(availabilityDio: dio).checkAvailability();

    expect(request.uri.path, '/mooc/index.php');
    expect(request.cancelToken, isNotNull);
  });

  test('public availability probe surfaces a network failure', () async {
    final error = DioException(
      requestOptions: RequestOptions(path: '/mooc/index.php'),
      type: .connectionError,
    );
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(onRequest: (_, handler) => handler.reject(error)),
      );

    await expectLater(
      NtutISchoolPlusService(
        availabilityDio: dio,
      ).checkAvailability(),
      throwsA(same(error)),
    );
  });

  test(
    'availability probe cancels stalled Dio work near five seconds',
    () async {
      late CancelToken token;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              token = options.cancelToken!;
              handler.reject(await token.whenCancel);
            },
          ),
        );
      final stopwatch = Stopwatch()..start();

      await expectLater(
        NtutISchoolPlusService(
          availabilityDio: dio,
        ).checkAvailability(),
        throwsA(
          isA<DioException>().having(
            (DioException e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );

      expect(token.isCancelled, isTrue);
      expect(stopwatch.elapsedMilliseconds, inInclusiveRange(4000, 6000));
    },
    timeout: const Timeout(Duration(seconds: 7)),
  );

  test('cookie-free Dio neither reads nor writes authenticated cookies', () {
    final dio = createDio(useCookies: false);

    expect(dio.interceptors.whereType<CookieManager>(), isEmpty);
    expect(dio.interceptors.whereType<NullHeaderInterceptor>(), hasLength(1));
  });
}
