import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/i_school_plus/ntut_i_school_plus_service.dart';
import 'package:tattoo/utils/http.dart';

void main() {
  group('NtutISchoolPlusService Error Handling', () {
    test(
      'getCourseList throws ISchoolPlusVpnRequiredException on connection error',
      () async {
        final dio = Dio()
          ..httpClientAdapter = _FailingAdapter(
            error: const SocketException('Connection refused / VPN required'),
            type: DioExceptionType.connectionError,
          );

        final service = NtutISchoolPlusService(dio: dio);

        expect(
          () => service.getCourseList(),
          throwsA(isA<ISchoolPlusVpnRequiredException>()),
        );
      },
    );

    test(
      'getCourseList throws SessionExpiredException on 403 response',
      () async {
        final dio = Dio()
          ..httpClientAdapter = _FailingAdapter(
            statusCode: 403,
            type: DioExceptionType.badResponse,
          );

        final service = NtutISchoolPlusService(dio: dio);

        expect(
          () => service.getCourseList(),
          throwsA(isA<SessionExpiredException>()),
        );
      },
    );

    test(
      'getStudents throws ISchoolPlusVpnRequiredException on timeout',
      () async {
        final dio = Dio()
          ..httpClientAdapter = _FailingAdapter(
            type: DioExceptionType.connectionTimeout,
          );

        final service = NtutISchoolPlusService(dio: dio);

        expect(
          () => service.getStudents((
            courseNumber: '352902',
            internalId: '10099386',
          )),
          throwsA(isA<ISchoolPlusVpnRequiredException>()),
        );
      },
    );

    test(
      'getMaterials throws ISchoolPlusVpnRequiredException on network failure',
      () async {
        final dio = Dio()
          ..httpClientAdapter = _FailingAdapter(
            error: const SocketException('Failed host lookup'),
            type: DioExceptionType.connectionError,
          );

        final service = NtutISchoolPlusService(dio: dio);

        expect(
          () => service.getMaterials((
            courseNumber: '352902',
            internalId: '10099386',
          )),
          throwsA(isA<ISchoolPlusVpnRequiredException>()),
        );
      },
    );

    test(
      'getMaterial throws ISchoolPlusVpnRequiredException on network failure',
      () async {
        final dio = Dio()
          ..httpClientAdapter = _FailingAdapter(
            type: DioExceptionType.receiveTimeout,
          );

        final service = NtutISchoolPlusService(dio: dio);

        expect(
          () => service.getMaterial((
            course: (courseNumber: '352902', internalId: '10099386'),
            title: 'Slide 1',
            href: 'res01',
          )),
          throwsA(isA<ISchoolPlusVpnRequiredException>()),
        );
      },
    );
  });
}

class _FailingAdapter implements HttpClientAdapter {
  final Object? error;
  final int? statusCode;
  final DioExceptionType type;

  _FailingAdapter({
    this.error,
    this.statusCode,
    this.type = DioExceptionType.unknown,
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (statusCode != null) {
      return ResponseBody.fromString(
        'Forbidden',
        statusCode!,
        headers: {
          Headers.contentTypeHeader: [Headers.textPlainContentType],
        },
      );
    }
    throw DioException(
      requestOptions: options,
      error: error,
      type: type,
    );
  }

  @override
  void close({bool force = false}) {}
}
