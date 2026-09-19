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

  test('concurrent roster operations do not mix selected courses', () async {
    protocol.pauseNextRoster = true;
    final first = service.getStudents(_courseA);
    await protocol.rosterRequested.future;

    final second = service.getStudents(_courseB);
    await pumpEventQueue();
    expect(protocol.switches, [_courseA.internalId]);

    protocol.releaseRoster.complete();
    expect((await first).single.id, _courseA.internalId);
    expect((await second).single.id, _courseB.internalId);
    expect(protocol.switches, [_courseA.internalId, _courseB.internalId]);
  });

  test('roster and materials cannot interleave course selection', () async {
    protocol.pauseNextRoster = true;
    final roster = service.getStudents(_courseA);
    await protocol.rosterRequested.future;

    final materials = service.getMaterials(_courseB);
    await pumpEventQueue();
    expect(protocol.selectedCourse, _courseA.internalId);

    protocol.releaseRoster.complete();
    await roster;
    await materials;
    expect(protocol.switches, [_courseA.internalId, _courseB.internalId]);
    expect(protocol.manifestCourse, _courseB.internalId);
  });

  test('material download remains inside its course operation', () async {
    protocol.pauseNextMaterialFetch = true;
    final material = service.getMaterial((
      course: _courseA,
      title: 'Lecture',
      href: 'lecture.pdf',
    ));
    await protocol.materialFetchRequested.future;

    final roster = service.getStudents(_courseB);
    await pumpEventQueue();
    expect(protocol.switches, [_courseA.internalId]);

    protocol.releaseMaterialFetch.complete();
    final result = await material;
    expect((await roster).single.id, _courseB.internalId);
    expect(result.downloadUrl.host, 'istream.ntut.edu.tw');
    expect(protocol.materialFetchCourse, _courseA.internalId);
    expect(protocol.switches, [_courseA.internalId, _courseB.internalId]);
  });

  test('failed course switch invalidates selected-course cache', () async {
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
  });

  test('session expiry invalidates selected-course cache', () async {
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

  test('sequential operations reuse a valid course selection', () async {
    await service.getStudents(_courseA);
    await service.getMaterials(_courseA);

    expect(protocol.switches, [_courseA.internalId]);
    expect(protocol.manifestCourse, _courseA.internalId);
  });
}

class _FakeISchoolProtocol extends Interceptor {
  final rosterRequested = Completer<void>();
  final releaseRoster = Completer<void>();
  final materialFetchRequested = Completer<void>();
  final releaseMaterialFetch = Completer<void>();
  final switches = <String>[];
  String? selectedCourse;
  String? manifestCourse;
  String? materialFetchCourse;
  bool pauseNextRoster = false;
  bool pauseNextMaterialFetch = false;
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
      if (pauseNextRoster) {
        pauseNextRoster = false;
        rosterRequested.complete();
        await releaseRoster.future;
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
    if (path.endsWith('path/launch.php')) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: "location.replace('/learn/path/manifest.php?cid=course')",
        ),
      );
      return;
    }
    if (path.endsWith('path/pathtree.php')) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data:
              '<form id="fetchResourceForm">'
              '<input name="read_key" value="token">'
              '</form>',
        ),
      );
      return;
    }
    if (path.endsWith('path/SCORM_fetchResource.php')) {
      materialFetchCourse = selectedCourse;
      if (pauseNextMaterialFetch) {
        pauseNextMaterialFetch = false;
        materialFetchRequested.complete();
        await releaseMaterialFetch.future;
      }
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data:
              '<script>location.replace('
              '"https://istream.ntut.edu.tw/video.mp4");</script>',
        ),
      );
      return;
    }
    handler.reject(
      DioException(requestOptions: options, error: 'Unexpected $path'),
    );
  }
}
