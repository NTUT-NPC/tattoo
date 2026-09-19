import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/i_school_plus/ntut_i_school_plus_service.dart';
import 'package:tattoo/utils/http.dart' show SessionExpiredException;

const _courseA = (courseNumber: 'A', internalId: '101');
const _courseB = (courseNumber: 'B', internalId: '202');

void main() {
  late _FakeISchoolProtocol protocol;
  late NtutISchoolPlusService service;

  setUp(() {
    protocol = _FakeISchoolProtocol();
    service = NtutISchoolPlusService(
      dio: Dio()..interceptors.add(protocol),
    );
  });

  test(
    'another course cannot be selected before the first roster completes',
    () async {
      final first = service.getStudents(_courseA);
      await protocol.rosterRequested.future;

      final second = service.getMaterials(_courseB);
      await pumpEventQueue();
      expect(protocol.selectedCourse, _courseA.internalId);
      expect(protocol.switches, [_courseA.internalId]);

      protocol.releaseRoster.complete();
      expect((await first).single.id, _courseA.internalId);
      await second;
      expect(protocol.switches, [_courseA.internalId, _courseB.internalId]);
      expect(protocol.manifestCourse, _courseB.internalId);
    },
  );

  test(
    'a cancelled waiter never selects its course or releases the queue',
    () async {
      final first = service.getStudents(_courseA);
      await protocol.rosterRequested.future;

      final token = CancelToken();
      final cancelled = expectLater(
        service.getMaterials(_courseB, cancelToken: token),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      token.cancel();
      await cancelled;
      final third = service.getMaterials(_courseA);
      await pumpEventQueue();
      expect(protocol.switches, [_courseA.internalId]);

      protocol.releaseRoster.complete();
      await first;
      await third;
      expect(protocol.switches, [_courseA.internalId]);
    },
  );

  test(
    'cancelling an active request releases the next course operation',
    () async {
      final token = CancelToken();
      final first = expectLater(
        service.getStudents(_courseA, cancelToken: token),
        throwsA(
          isA<DioException>().having(
            (error) => error.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      await protocol.rosterRequested.future;
      final second = service.getMaterials(_courseB);

      token.cancel();
      await first;
      await second;
      expect(protocol.switches, [_courseA.internalId, _courseB.internalId]);
      expect(protocol.manifestCourse, _courseB.internalId);
    },
  );

  test(
    'failed course switch invalidates the old selected-course cache',
    () async {
      protocol.releaseRoster.complete();
      await service.getStudents(_courseA);
      protocol.failNextSwitch = true;
      await expectLater(
        service.getMaterials(_courseB),
        throwsA(isA<DioException>()),
      );

      await service.getStudents(_courseA);
      expect(protocol.switches, [
        _courseA.internalId,
        _courseB.internalId,
        _courseA.internalId,
      ]);
    },
  );

  test('session expiry invalidates the selected-course cache', () async {
    protocol.releaseRoster.complete();
    await service.getStudents(_courseA);
    protocol.expireNextRoster = true;
    await expectLater(
      service.getStudents(_courseA),
      throwsA(
        isA<DioException>().having(
          (error) => error.error,
          'wrapped error',
          isA<SessionExpiredException>(),
        ),
      ),
    );

    await service.getStudents(_courseA);
    expect(protocol.switches, [_courseA.internalId, _courseA.internalId]);
  });
}

class _FakeISchoolProtocol extends Interceptor {
  final rosterRequested = Completer<void>();
  final releaseRoster = Completer<void>();
  final switches = <String>[];
  String? selectedCourse;
  String? manifestCourse;
  bool failNextSwitch = false;
  bool expireNextRoster = false;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    if (path.endsWith('goto_course.php')) {
      final id = RegExp(r'<course_id>([^<]+)</course_id>')
          .firstMatch(options.data as String)!
          .group(1)!;
      switches.add(id);
      if (failNextSwitch) {
        failNextSwitch = false;
        handler.reject(
          DioException(requestOptions: options, type: .connectionError),
        );
        return;
      }
      selectedCourse = id;
      handler.resolve(
        Response(requestOptions: options, data: '', statusCode: 200),
      );
      return;
    }
    if (path.endsWith('learn_ranking.php')) {
      if (!rosterRequested.isCompleted) {
        rosterRequested.complete();
        try {
          await Future.any([
            releaseRoster.future,
            if (options.cancelToken case final token?)
              token.whenCancel.then((error) => throw error),
          ]);
        } on DioException catch (error) {
          handler.reject(error);
          return;
        }
      }
      if (expireNextRoster) {
        expireNextRoster = false;
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response(requestOptions: options, statusCode: 403),
            type: .badResponse,
          ),
          true,
        );
        return;
      }
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data:
              '<div class="content"><table class="data2"><tbody>'
              '<tr><td></td><td><span>$selectedCourse (Student)</span></td></tr>'
              '</tbody></table></div>',
        ),
      );
      return;
    }
    if (path.endsWith('path/SCORM_loadCA.php')) {
      manifestCourse = selectedCourse;
      handler.resolve(
        Response(requestOptions: options, data: '<manifest/>', statusCode: 200),
      );
      return;
    }
    handler.reject(
      DioException(requestOptions: options, error: 'Unexpected $path'),
    );
  }
}
