import 'dart:io';

import 'package:dio_redirect_interceptor/dio_redirect_interceptor.dart';
import 'package:html/parser.dart';
import 'package:tattoo/services/i_school_plus/i_school_plus_service.dart';
import 'package:tattoo/utils/http.dart';

class NtutISchoolPlusService implements ISchoolPlusService {
  late final Dio _iSchoolPlusDio;

  /// The currently selected course, used to avoid redundant server-side
  /// course switches.
  String? _selectedInternalId;

  NtutISchoolPlusService() {
    _iSchoolPlusDio = createDio()
      ..options.baseUrl = 'https://istudy.ntut.edu.tw/learn/'
      ..interceptors.insert(0, InvalidCookieFilter()) // Prepend cookie filter
      ..transformer = PlainTextTransformer();
  }

  @override
  Future<List<ISchoolCourseDto>> getCourseList() async {
    final response = await _iSchoolPlusDio.get('mooc_sysbar.php');

    final document = parse(response.data);
    final courseSelect = document.getElementById('selcourse');
    if (courseSelect == null) return [];

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

  Future<void> _selectCourse(ISchoolCourseDto course) async {
    if (course.internalId == _selectedInternalId) return;

    await _iSchoolPlusDio.post(
      'goto_course.php',
      data:
          '<manifest><ticket/><course_id>${course.internalId}</course_id><env/></manifest>',
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    _selectedInternalId = course.internalId;
  }

  @override
  Future<List<StudentDto>> getStudents(ISchoolCourseDto course) async {
    await _selectCourse(course);

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
  }

  @override
  Future<List<MaterialRefDto>> getMaterials(ISchoolCourseDto course) async {
    await _selectCourse(course);

    // Fetch and parse the SCORM manifest XML for file listings
    final manifestResponse = await _iSchoolPlusDio.get('path/SCORM_loadCA.php');
    final manifestDocument = parse(manifestResponse.data);

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
  ) async {
    await _selectCourse(material.course);

    // Step 1: Get launch.php to extract the course ID (cid)
    final launchResponse = await _iSchoolPlusDio.get('path/launch.php');

    // Extract cid from the JavaScript
    // e.g.: parent.s_catalog.location.replace('/learn/path/manifest.php?cid=...')
    final cidMatch = RegExp(r"cid=([^']+)").firstMatch(launchResponse.data);
    if (cidMatch == null) {
      throw Exception('Could not extract course ID from launch page.');
    }
    final cid = cidMatch.group(1)!;

    // Step 2: Get resource token from the course material tree endpoint
    // It contains a form with a token needed to fetch downloadable resources
    final materialTreeResponse = await _iSchoolPlusDio.get(
      'path/pathtree.php',
      queryParameters: {'cid': cid},
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

      final previewUri = Uri.tryParse(location);
      if (previewUri == null) {
        throw Exception('Invalid redirect URI: $location');
      }

      return (
        downloadUrl: previewUri.replace(path: "download.php"),
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
      throw Exception('Could not extract download URI from response.');
    }

    // URI can be relative, so resolve against base URL
    final baseUrl = '${_iSchoolPlusDio.options.baseUrl}path/';
    final downloadUri = Uri.parse(baseUrl).resolve(quoteMatch.group(2)!);

    // Case 2: Material is a course recording
    if (downloadUri.host.contains("istream.ntut.edu.tw")) {
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
      final viewPdfResponse = await _iSchoolPlusDio.getUri(downloadUri);

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
}
