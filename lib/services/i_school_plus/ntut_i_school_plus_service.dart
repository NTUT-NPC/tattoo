import 'dart:async';
import 'dart:io';

import 'package:dio_redirect_interceptor/dio_redirect_interceptor.dart';
import 'package:html/parser.dart';
import 'package:path/path.dart' as p;
import 'package:tattoo/services/i_school_plus/i_school_plus_service.dart';
import 'package:tattoo/utils/http.dart';
import 'package:tattoo/utils/material_file_name.dart';

class NtutISchoolPlusService implements ISchoolPlusService {
  static const _requestTimeout = Duration(seconds: 20);
  static const _availabilityTimeout = Duration(seconds: 5);

  late final Dio _iSchoolPlusDio;
  late final Dio _availabilityDio;

  /// The currently selected course, used to avoid redundant server-side
  /// course switches.
  String? _selectedInternalId;
  Future<void> _courseOperationTail = Future.value();

  /// [dio] permits deterministic protocol tests without contacting iSchool+.
  NtutISchoolPlusService({Dio? dio, Dio? availabilityDio}) {
    _iSchoolPlusDio = (dio ?? createDio())
      ..options.baseUrl = 'https://istudy.ntut.edu.tw/learn/'
      ..options.connectTimeout = _requestTimeout
      ..options.sendTimeout = _requestTimeout
      ..options.receiveTimeout = _requestTimeout
      ..interceptors.insert(0, InvalidCookieFilter()) // Prepend cookie filter
      ..interceptors.add(
        _SessionCheckInterceptor(
          onSessionExpired: () => _selectedInternalId = null,
        ),
      )
      ..transformer = PlainTextTransformer();
    _availabilityDio = (availabilityDio ?? createDio(useCookies: false))
      ..options.connectTimeout = _availabilityTimeout
      ..options.sendTimeout = _availabilityTimeout
      ..options.receiveTimeout = _availabilityTimeout;
  }

  @override
  Future<void> checkAvailability() async {
    final cancelToken = CancelToken();
    final timer = Timer(
      _availabilityTimeout,
      () => cancelToken.cancel('I-School Plus availability probe timed out'),
    );
    try {
      await Future.any([
        _availabilityDio.get<void>(
          'https://istudy.ntut.edu.tw/mooc/index.php',
          cancelToken: cancelToken,
          options: Options(responseType: .bytes),
        ),
        cancelToken.whenCancel.then((error) => throw error),
      ]);
    } finally {
      timer.cancel();
    }
  }

  @override
  Future<List<ISchoolCourseDto>> getCourseList() async {
    // A newly fetched list reflects the current server session. Force the next
    // course-scoped operation to establish its selection in that session.
    _selectedInternalId = null;
    final response = await _iSchoolPlusDio.get('mooc_sysbar.php');

    final document = parse(response.data);
    final courseSelect = document.getElementById('selcourse');
    if (courseSelect == null) {
      throw const SessionExpiredException(
        'ISchoolPlus course selector is missing',
      );
    }

    // Options may be inside <optgroup> elements, so use querySelectorAll.
    // Example option: <option value="10099386">1141_智慧財產權_352902</option>
    final options = courseSelect.querySelectorAll('option');

    final courses = <ISchoolCourseDto>[];
    for (final option in options) {
      final internalId = option.attributes['value'];
      if (internalId == null || internalId.isEmpty) continue;

      // Extract course number from the end of the option text
      final text = option.text;
      final underscoreIdx = text.lastIndexOf('_');
      if (underscoreIdx == -1) continue;
      final courseNumber = text.substring(underscoreIdx + 1).trim();
      if (courseNumber.isEmpty) continue;

      courses.add((courseNumber: courseNumber, internalId: internalId));
    }

    return courses;
  }

  /// Runs course selection and all dependent requests as one critical section.
  Future<T> _withSelectedCourse<T>(
    ISchoolCourseDto course,
    Future<T> Function() operation, {
    CancelToken? cancelToken,
  }) {
    final task = _courseOperationTail.then((_) async {
      if (cancelToken?.cancelError case final error?) throw error;
      await _selectCourse(course, cancelToken: cancelToken);
      return operation();
    });
    _courseOperationTail = task.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return task;
  }

  Future<void> _selectCourse(
    ISchoolCourseDto course, {
    CancelToken? cancelToken,
  }) async {
    if (course.internalId == _selectedInternalId) return;

    // A failed POST may still have reached the server, so neither the old nor
    // the requested selection is trustworthy until a later successful switch.
    _selectedInternalId = null;
    await _iSchoolPlusDio.post(
      'goto_course.php',
      cancelToken: cancelToken,
      data:
          '<manifest><ticket/><course_id>${course.internalId}</course_id><env/></manifest>',
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    _selectedInternalId = course.internalId;
  }

  @override
  Future<List<StudentDto>> getStudents(
    ISchoolCourseDto course,
  ) => _withSelectedCourse(course, () async {
    final response = await _iSchoolPlusDio.get('learn_ranking.php');

    // Parse the HTML and extract the table of student rankings
    final document = parse(response.data);
    final studyRankingsTable = document.querySelector('.content>.data2 tbody');
    if (studyRankingsTable == null) {
      throw Exception(
        'No student data found for course ${course.courseNumber}.',
      );
    }

    // Extract second column from each row for student ID and name
    // Example cell: "111360109 (何承軒)"
    final students = studyRankingsTable.children
        .map((row) => row.children[1].children.first.text)
        .toList();
    if (students.isEmpty) {
      throw Exception('No students found for course ${course.courseNumber}.');
    }

    return students
        .map((student) {
          final parts = student.split(' (');
          final id = parts[0];
          final name = parts[1].replaceAll(')', '').trim();

          return (
            id: id.isEmpty ? null : id,
            name: name.isEmpty ? null : name,
          );
        })
        .where(
          (student) => student.id != 'istudyoaa', // Filter out system account
        )
        .toList();
  });

  @override
  Future<List<MaterialRefDto>> getMaterials(
    ISchoolCourseDto course,
  ) => _withSelectedCourse(course, () => _getMaterials(course));

  Future<List<MaterialRefDto>> _getMaterials(
    ISchoolCourseDto course, {
    CancelToken? cancelToken,
  }) async {
    // Fetch and parse the SCORM manifest XML for file listings
    final manifestResponse = await _iSchoolPlusDio.get(
      'path/SCORM_loadCA.php',
      cancelToken: cancelToken,
      // Without the material page Referer, the server returns an HTML browser
      // challenge with status 200 instead of the SCORM manifest.
      options: Options(
        headers: {
          HttpHeaders.refererHeader:
              'https://istudy.ntut.edu.tw/learn/path/launch.php',
        },
      ),
    );
    final manifestDocument = parse(manifestResponse.data);
    if (manifestDocument.querySelector('manifest') == null) {
      throw DioException(
        requestOptions: manifestResponse.requestOptions,
        response: manifestResponse,
        type: .badResponse,
        message: 'I-School Plus returned an invalid material manifest',
      );
    }

    // Extract all <item> elements that have identifierref attribute (actual files)
    // Items without identifierref are folders/directories and are excluded
    final items = manifestDocument.querySelectorAll('item[identifierref]');

    return items.map((item) {
      final titleElement = item.querySelector('title');
      final title = titleElement?.text.split('\t').first.trim();

      // Find the corresponding <resource> element
      final identifierRef = item.attributes['identifierref']!;
      final resource = manifestDocument.querySelector(
        'resource[identifier="$identifierRef"]',
      );

      final href = resource?.attributes['href'];

      return (
        course: course,
        title: title,
        href: href,
      );
    }).toList();
  }

  @override
  Future<MaterialDto> getMaterial(
    MaterialRefDto material,
  ) => _withSelectedCourse(material.course, () => _getMaterial(material));

  Future<MaterialDto> _getMaterial(
    MaterialRefDto material, {
    CancelToken? cancelToken,
    bool retryStaleReference = true,
  }) async {
    if (cancelToken?.cancelError case final error?) throw error;
    // Step 1: Get launch.php to extract the course ID (cid)
    final launchResponse = await _iSchoolPlusDio.get(
      'path/launch.php',
      cancelToken: cancelToken,
    );

    // Both the current inline `var cid = '...'` and the older frame redirect
    // expose the access ID used by the material tree and resource form.
    final launchBody = launchResponse.data as String;
    final cid =
        RegExp(r'''\bcid\s*=\s*(['"])([^'"]+)\1''')
            .firstMatch(launchBody)
            ?.group(2) ??
        RegExp(r'''[?&]cid=([^'"&\s]+)''').firstMatch(launchBody)?.group(1);
    if (cid == null) {
      throw DioException(
        requestOptions: launchResponse.requestOptions,
        response: launchResponse,
        type: .badResponse,
        message: 'Could not extract course ID from launch page',
      );
    }

    // Step 2: Get resource token from the course material tree endpoint
    // It contains a form with a token needed to fetch downloadable resources
    final materialTreeResponse = await _iSchoolPlusDio.get(
      'path/pathtree.php',
      queryParameters: {'cid': cid},
      cancelToken: cancelToken,
    );

    // Extract the read_key token from the HTML form
    final materialTreeDocument = parse(materialTreeResponse.data);
    final readKeyInput = materialTreeDocument.querySelector(
      '#fetchResourceForm>input[name="read_key"][value]',
    );
    if (readKeyInput == null) {
      throw Exception('Could not find read_key in material tree page.');
    }
    final fetchResourceToken = readKeyInput.attributes['value']!;

    // Step 3: Submit resource form and get resource URI
    final dioWithoutRedirects = _iSchoolPlusDio.clone()
      ..interceptors.removeWhere(
        (interceptor) => interceptor is RedirectInterceptor,
      );

    final resourceResponse = await dioWithoutRedirects.post(
      'path/SCORM_fetchResource.php',
      cancelToken: cancelToken,
      data: {
        'href': '@${material.href!}',
        'course_id': cid,
        'read_key': fetchResourceToken,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    // Case 1: Response is a redirect
    // Replace preview URL with download URL
    if (resourceResponse.statusCode == HttpStatus.found) {
      final location =
          resourceResponse.headers[HttpHeaders.locationHeader]?.first;
      if (location == null) {
        throw Exception('Redirect location header is missing.');
      }

      final locationUri = Uri.tryParse(location);
      if (locationUri == null) {
        throw Exception('Invalid redirect URI: $location');
      }

      final previewUri = resourceResponse.realUri.resolveUri(locationUri);
      if (_isStream(previewUri)) {
        return (downloadUrl: previewUri, referer: null, streamable: true);
      }
      return (
        downloadUrl: previewUri
            .resolve('download.php')
            .replace(query: previewUri.query),
        referer: null,
        streamable: false,
      );
    }

    // Response is HTML with embedded download script, e.g.,
    // <script>location.replace("viewPDF.php?id=KheOh_TuNgPJOQTEmRW1zg,,");</script>

    // URI can be enclosed in either single or double quotes
    final quoteRegExp = RegExp(r'''(['"])([^'"]+)\1''');
    final quoteMatch = quoteRegExp.firstMatch(resourceResponse.data);
    if (quoteMatch == null || quoteMatch.groupCount < 2) {
      // Resource hrefs change after re-authentication. Resolve a uniquely named
      // cached item against the current manifest without reopening the session.
      if (retryStaleReference && material.title?.trim().isNotEmpty == true) {
        final current = await _getMaterials(
          material.course,
          cancelToken: cancelToken,
        );
        final matching = current
            .where(
              (item) =>
                  item.title?.trim() == material.title?.trim() &&
                  item.href?.isNotEmpty == true,
            )
            .toList();
        if (matching.length == 1 && matching.single.href != material.href) {
          return _getMaterial(
            matching.single,
            cancelToken: cancelToken,
            retryStaleReference: false,
          );
        }
      }
      throw DioException(
        requestOptions: resourceResponse.requestOptions,
        response: resourceResponse,
        type: .badResponse,
        message: 'Could not resolve the current material resource',
      );
    }

    // URI can be relative, so resolve against base URL
    final baseUrl = '${_iSchoolPlusDio.options.baseUrl}path/';
    final downloadUri = Uri.parse(baseUrl).resolve(quoteMatch.group(2)!);

    // Case 2: Material is a course recording
    if (_isStream(downloadUri)) {
      // iStream videos can be streamed directly or downloaded
      // Testing confirmed no referer required
      return (
        downloadUrl: downloadUri,
        referer: null,
        streamable: true,
      );
    }

    // Case 3: Material is a PDF
    if (downloadUri.path.contains('viewPDF.php')) {
      // Fetch and find the value of DEFAULT_URL in JavaScript
      final viewPdfResponse = await _iSchoolPlusDio.getUri(
        downloadUri,
        cancelToken: cancelToken,
      );

      final defaultUrlRegExp = RegExp(r'DEFAULT_URL[ =]+\"(.+)\"');
      final defaultUrlMatch = defaultUrlRegExp.firstMatch(viewPdfResponse.data);
      if (defaultUrlMatch == null || defaultUrlMatch.groupCount < 1) {
        throw Exception('Could not find DEFAULT_URL in PDF viewer page.');
      }
      final defaultUrl = defaultUrlMatch.group(1)!;

      return (
        downloadUrl: Uri.parse(baseUrl).resolve(defaultUrl),
        referer: downloadUri.toString(),
        streamable: false,
      );
    }

    // Case 4: Material is a standard downloadable file
    return (
      downloadUrl: downloadUri,
      referer: null,
      streamable: false,
    );
  }

  bool _isStream(Uri uri) => uri.host.toLowerCase() == 'istream.ntut.edu.tw';

  @override
  Future<MaterialFileDto> downloadMaterial(
    MaterialRefDto material,
    String directory, {
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) => _withSelectedCourse(material.course, () async {
    if (cancelToken?.cancelError case final error?) throw error;
    final access = await _getMaterial(material, cancelToken: cancelToken);
    if (access.streamable || _isStream(access.downloadUrl)) {
      throw UnsupportedError('iStream downloads are not supported');
    }
    if (!['http', 'https'].contains(access.downloadUrl.scheme) ||
        access.downloadUrl.host.isEmpty) {
      throw StateError('Material download URL must be HTTP(S)');
    }
    var uri = access.downloadUrl;
    for (var redirects = 0; redirects <= 10; redirects++) {
      if (_isStream(uri)) {
        throw UnsupportedError('iStream downloads are not supported');
      }
      if (!['http', 'https'].contains(uri.scheme) || uri.host.isEmpty) {
        throw StateError('Material download URL must be HTTP(S)');
      }
      final response = await _iSchoolPlusDio.getUri<ResponseBody>(
        uri,
        cancelToken: cancelToken,
        options: Options(
          responseType: .stream,
          validateStatus: (status) =>
              status != null &&
              ((status >= 200 && status < 300) ||
                  [301, 302, 303, 307, 308].contains(status)),
          followRedirects: false,
          extra: {RedirectInterceptor.followRedirects: false},
          receiveTimeout: const Duration(minutes: 2),
          headers: {HttpHeaders.refererHeader: ?access.referer},
        ),
      );
      final body = response.data!;
      if ([301, 302, 303, 307, 308].contains(response.statusCode)) {
        await body.stream.listen((_) {}).cancel();
        final location = response.headers.value(HttpHeaders.locationHeader);
        if (location == null || redirects == 10) {
          throw StateError('Invalid material redirect');
        }
        uri = response.realUri.resolve(location);
        continue;
      }
      final fileName = materialFileName(
        disposition: response.headers.value('content-disposition'),
        title: material.title,
        contentType: response.headers.value(HttpHeaders.contentTypeHeader),
      );
      final file = File(p.join(directory, fileName));
      final iterator = StreamIterator(body.stream);
      cancelToken?.whenCancel.then((_) => iterator.cancel());
      RandomAccessFile? output;
      var completed = false;
      try {
        output = await file.open(mode: FileMode.write);
        var received = 0;
        final total =
            int.tryParse(
              response.headers.value(HttpHeaders.contentLengthHeader) ?? '',
            ) ??
            -1;
        while (await iterator.moveNext()) {
          if (cancelToken?.cancelError case final error?) throw error;
          final bytes = iterator.current;
          await output.writeFrom(bytes);
          received += bytes.length;
          onReceiveProgress?.call(received, total);
        }
        if (cancelToken?.cancelError case final error?) throw error;
        completed = true;
        return (path: file.path, fileName: fileName);
      } finally {
        await iterator.cancel();
        await output?.close();
        if (!completed && await file.exists()) await file.delete();
      }
    }
    throw StateError('Too many material redirects');
  }, cancelToken: cancelToken);
}

/// Detects expired sessions in ISchoolPlus responses.
///
/// iSchool+ returns HTTP 403 when the session has expired, which Dio would
/// normally surface as a [DioException]. This interceptor converts it to a
/// [SessionExpiredException] so that [AuthRepository.withAuth] retries with
/// re-authentication instead of treating it as a network error.
class _SessionCheckInterceptor extends Interceptor {
  final void Function() onSessionExpired;

  const _SessionCheckInterceptor({required this.onSessionExpired});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 403) {
      onSessionExpired();
      throw const SessionExpiredException(
        'ISchoolPlus session expired',
      );
    }
    handler.next(err);
  }
}
