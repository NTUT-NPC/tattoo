import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/i_school_plus/ntut_i_school_plus_service.dart';

void main() {
  test(
    'availability probe is bounded even when the adapter ignores timeout',
    () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final cancelToken = options.cancelToken!;
              final error = await cancelToken.whenCancel;
              handler.reject(error);
            },
          ),
        );
      final service = NtutISchoolPlusService(availabilityDio: dio);

      final stopwatch = Stopwatch()..start();
      await expectLater(
        service.checkAvailability(),
        throwsA(
          isA<DioException>().having(
            (error) => error.type == DioExceptionType.cancel,
            'is cancelled',
            isTrue,
          ),
        ),
      );
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 6)));
    },
  );
}
