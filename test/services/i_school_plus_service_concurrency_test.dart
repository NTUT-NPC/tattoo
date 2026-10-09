import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

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
      dio: Dio(
        BaseOptions(validateStatus: (status) => status != null && status < 400),
      )..interceptors.add(protocol),
    );
  });

  test(
    'file transfer keeps course selection locked and sends PDF referer',
    () async {
      final directory = await Directory.systemTemp.createTemp('material-test-');
      addTearDown(() => directory.delete(recursive: true));
      protocol.resourceUrl = 'viewPDF.php?id=token';
      protocol.fileBody = StreamController<Uint8List>();
      final token = CancelToken();
      final download = service.downloadMaterial(
        (course: _courseA, title: 'Lecture', href: 'resource'),
        directory.path,
        cancelToken: token,
      );
      await protocol.fileRequested.future;
      final roster = service.getStudents(_courseB);
      await pumpEventQueue();
      expect(protocol.switches, [_courseA.internalId]);
      expect(
        protocol.fileOptions!.headers[HttpHeaders.refererHeader],
        'https://istudy.ntut.edu.tw/learn/path/viewPDF.php?id=token',
      );
      expect(protocol.fileOptions!.cancelToken, same(token));
      protocol.fileBody!.add(Uint8List.fromList([1, 2, 3, 4]));
      await protocol.fileBody!.close();
      final file = await download;
      expect(file.fileName, 'Lecture.pdf');
      expect(await File(file.path).readAsBytes(), [1, 2, 3, 4]);
      await roster;
      expect(protocol.switches, [_courseA.internalId, _courseB.internalId]);
    },
  );

  test('iStream redirects remain streams and are never downloaded', () async {
    final directory = await Directory.systemTemp.createTemp('material-test-');
    addTearDown(() => directory.delete(recursive: true));
    protocol.redirectResource = true;
    final material = (course: _courseA, title: 'Stream', href: 'resource');
    expect((await service.getMaterial(material)).streamable, isTrue);
    await expectLater(
      service.downloadMaterial(material, directory.path),
      throwsUnsupportedError,
    );
    expect(await directory.list().isEmpty, isTrue);
    expect(protocol.fileOptions, isNull);
  });

  test(
    'file redirects to iStream stop before saving or fetching the stream',
    () async {
      final directory = await Directory.systemTemp.createTemp('material-test-');
      addTearDown(() => directory.delete(recursive: true));
      protocol.resourceUrl = 'files/notes.pdf';
      protocol.fileRedirect = 'https://istream.ntut.edu.tw/video.mp4';
      await expectLater(
        service.downloadMaterial((
          course: _courseA,
          title: 'Notes',
          href: 'resource',
        ), directory.path),
        throwsUnsupportedError,
      );
      expect(await directory.list().isEmpty, isTrue);
      expect(protocol.fileOptions!.extra['followRedirects'], isFalse);
    },
  );

  test(
    'relative preview redirects retain query and download directory',
    () async {
      protocol.redirectResource = true;
      protocol.resourceUrl = 'preview.php?id=token';
      final access = await service.getMaterial((
        course: _courseA,
        title: 'File',
        href: 'resource',
      ));
      expect(
        access.downloadUrl.toString(),
        'https://istudy.ntut.edu.tw/learn/path/download.php?id=token',
      );
    },
  );

  test(
    'cancelling a file transfer deletes partial data and releases queue',
    () async {
      final directory = await Directory.systemTemp.createTemp('material-test-');
      addTearDown(() => directory.delete(recursive: true));
      protocol.resourceUrl = 'files/notes.pdf';
      protocol.fileBody = StreamController<Uint8List>();
      final token = CancelToken();
      final download = service.downloadMaterial(
        (course: _courseA, title: 'Lecture', href: 'resource'),
        directory.path,
        cancelToken: token,
      );
      final failure = expectLater(
        download,
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      await protocol.fileRequested.future;
      protocol.fileBody!.add(Uint8List.fromList([1, 2]));
      await pumpEventQueue();
      token.cancel();
      await failure;
      await protocol.fileBody!.close();
      expect(await directory.list().isEmpty, isTrue);
      await service.getStudents(_courseB);
      expect(protocol.selectedCourse, _courseB.internalId);
    },
  );

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

  test('missing course selector reports an expired session', () async {
    protocol.courseListWithoutSelector = true;

    await expectLater(
      service.getCourseList(),
      throwsA(isA<SessionExpiredException>()),
    );
  });

  test(
    'material manifest requests include the material page Referer',
    () async {
      await service.getMaterials(_courseA);
      expect(
        protocol.manifestOptions!.headers[HttpHeaders.refererHeader],
        'https://istudy.ntut.edu.tw/learn/path/launch.php',
      );
    },
  );

  test(
    'current launch pages expose the course access ID as a variable',
    () async {
      protocol.inlineCourseId = true;
      expect(
        (await service.getMaterial((
          course: _courseA,
          title: 'Video',
          href: 'resource',
        ))).streamable,
        isTrue,
      );
    },
  );

  test('cached resource codes are renewed after the session changes', () async {
    protocol.rotateResource = true;
    final access = await service.getMaterial((
      course: _courseA,
      title: 'Lecture',
      href: 'stale',
    ));
    expect(access.streamable, isTrue);
    expect(protocol.requestedHrefs, ['@stale', '@resource']);
    expect(protocol.switches, [_courseA.internalId]);
  });

  test('ambiguous titles never download a different resource', () async {
    protocol.rotateResource = true;
    protocol.duplicateMaterialTitle = true;
    await expectLater(
      service.getMaterial((course: _courseA, title: 'Lecture', href: 'stale')),
      throwsA(isA<DioException>()),
    );
    expect(protocol.requestedHrefs, ['@stale']);
  });

  test('an invalid launch page reports a response error', () async {
    protocol.invalidLaunch = true;
    await expectLater(
      service.getMaterial((course: _courseA, title: 'File', href: 'resource')),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.badResponse,
        ),
      ),
    );
  });

  test(
    'an HTML challenge cannot be treated as an empty material list',
    () async {
      protocol.invalidManifest = true;
      await expectLater(
        service.getMaterials(_courseA),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.badResponse,
          ),
        ),
      );
      protocol.invalidManifest = false;
      expect(await service.getMaterials(_courseA), isEmpty);
    },
  );
}

class _FakeISchoolProtocol extends Interceptor {
  final rosterRequested = Completer<void>();
  final releaseRoster = Completer<void>();
  final materialFetchRequested = Completer<void>();
  final releaseMaterialFetch = Completer<void>();
  final switches = <String>[];
  String resourceUrl = 'https://istream.ntut.edu.tw/video.mp4';
  bool redirectResource = false;
  final fileRequested = Completer<void>();
  StreamController<Uint8List>? fileBody;
  RequestOptions? fileOptions;
  String? fileRedirect;
  String? selectedCourse;
  String? manifestCourse;
  String? materialFetchCourse;
  bool pauseNextRoster = false;
  bool pauseNextMaterialFetch = false;
  bool failNextSwitch = false;
  bool expireNextRoster = false;
  bool courseListWithoutSelector = false;
  bool invalidManifest = false;
  bool inlineCourseId = false;
  bool invalidLaunch = false;
  bool rotateResource = false;
  bool duplicateMaterialTitle = false;
  final requestedHrefs = <String>[];
  RequestOptions? manifestOptions;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    if (path.endsWith('mooc_sysbar.php')) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: courseListWithoutSelector
              ? '<html><body>Portal login required</body></html>'
              : '<select id="selcourse"></select>',
        ),
      );
      return;
    }
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
      manifestOptions = options;
      manifestCourse = selectedCourse;
      handler.resolve(
        Response(
          requestOptions: options,
          data: invalidManifest
              ? '<html><script src="/TSPD/challenge"></script></html>'
              : rotateResource
              ? '<manifest><item identifierref="one"><title>Lecture</title></item>'
                    '<resource identifier="one" href="resource"/>'
                    '${duplicateMaterialTitle ? '<item identifierref="two"><title>Lecture</title></item><resource identifier="two" href="other"/>' : ''}'
                    '</manifest>'
              : '<manifest/>',
          statusCode: 200,
        ),
      );
      return;
    }
    if (path.endsWith('path/launch.php')) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: invalidLaunch
              ? '<html>Unavailable</html>'
              : inlineCourseId
              ? 'var cid = "course";'
              : "location.replace('/learn/path/manifest.php?cid=course')",
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
      final href = (options.data as Map)['href'] as String;
      requestedHrefs.add(href);
      if (rotateResource && href == '@stale') {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: '<html>Expired material reference</html>',
          ),
        );
        return;
      }
      materialFetchCourse = selectedCourse;
      if (pauseNextMaterialFetch) {
        pauseNextMaterialFetch = false;
        materialFetchRequested.complete();
        await releaseMaterialFetch.future;
      }
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: redirectResource ? 302 : 200,
          headers: Headers.fromMap({
            if (redirectResource) HttpHeaders.locationHeader: [resourceUrl],
          }),
          data:
              '<script>location.replace('
              '"$resourceUrl");</script>',
        ),
      );
      return;
    }
    if (path.contains('viewPDF.php')) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: 'var DEFAULT_URL = "files/notes.pdf";',
        ),
      );
      return;
    }
    if (path.endsWith('notes.pdf')) {
      fileOptions = options;
      fileRequested.complete();
      if (fileRedirect case final location?) {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 302,
            headers: Headers.fromMap({
              'location': [location],
            }),
            data: ResponseBody.fromString(
              '',
              302,
              headers: {
                'location': [location],
              },
            ),
          ),
        );
        return;
      }
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          headers: Headers.fromMap({
            'content-disposition': [
              'attachment; filename="notes.pdf"',
            ],
          }),
          data: ResponseBody(
            fileBody!.stream,
            200,
            headers: {
              'content-disposition': ['attachment; filename="notes.pdf"'],
            },
          ),
        ),
      );
      return;
    }
    handler.reject(
      DioException(requestOptions: options, error: 'Unexpected $path'),
    );
  }
}
