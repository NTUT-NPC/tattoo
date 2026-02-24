import 'dart:io';

import 'package:dio_redirect_interceptor/dio_redirect_interceptor.dart';
import 'package:html/parser.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/utils/http.dart';

/// Course reference from the iSchool+ course selection sidebar.
///
/// Obtained from [ISchoolPlusService.getCourseList] and required by all
/// other iSchool+ operations. Contains the internal ID needed to select
/// the course server-side.
typedef ISchoolCourseDto = ({
  /// Course offering number from the course system (e.g., "352902").
  String courseNumber,

  /// Internal iSchool+ course identifier (e.g., "10099386").
  ///
  /// Used by [ISchoolPlusService] to select the course via `goto_course.php`.
  String internalId,
});

/// Student enrolled in an i-School Plus course.
typedef StudentDto = ({
  /// Student's NTUT ID (e.g., "111360109").
  String? id,

  /// Student's full name.
  String? name,
});

/// Reference to a course material file in i-School Plus.
typedef MaterialRefDto = ({
  /// The course this material belongs to.
  ISchoolCourseDto course,

  /// Title/filename of the material.
  String? title,

  /// SCORM resource identifier for the material.
  ///
  /// This is an encoded identifier from the SCORM manifest.
  /// This value is used internally by I-School Plus to locate the resource.
  String? href,
});

/// Downloadable course material with its access information.
typedef MaterialDto = ({
  /// Direct download URL for the material file.
  /// Can also be used for streaming media content.
  Uri downloadUrl,

  /// Optional Referer URL for some downloads (e.g., PDF viewer pages).
  /// If non-null, must be included as the HTTP Referer header when
  /// downloading or streaming. For other materials, this is `null`
  /// and no Referer header is required.
  String? referer,

  /// Whether this material can be streamed (e.g., video/audio recordings).
  bool streamable,
});

/// Provides the singleton [ISchoolPlusService] instance.
final iSchoolPlusServiceProvider = Provider<ISchoolPlusService>(
  (ref) => ISchoolPlusService(),
);

/// Service for accessing NTUT's I-School Plus learning management system.
///
/// This service provides access to:
/// - Course materials and files
/// - Student rosters and rankings
/// - Course announcements (not yet implemented)
/// - Assignment subscriptions (not yet implemented)
///
/// Authentication is required through [PortalService.sso] with
/// [PortalServiceCode.iSchoolPlusService] before using this service.
///
/// Call [getCourseList] first to obtain [ISchoolCourseDto] references,
/// then pass them to other methods. Not all courses from the course system
/// are available on I-School Plus (e.g., internships, early-semester courses).
///
/// Data is parsed from HTML/XML pages as NTUT does not provide a REST API.
class ISchoolPlusService {
  late final Dio _iSchoolPlusDio;

  /// The currently selected course, used to avoid redundant server-side
  /// course switches.
  String? _selectedInternalId;

  ISchoolPlusService() {
    _iSchoolPlusDio = createDio()
      ..options.baseUrl = 'https://istudy.ntut.edu.tw/learn/'
      ..interceptors.insert(0, InvalidCookieFilter()) // Prepend cookie filter
      ..transformer = PlainTextTransformer();
  }

  /// Fetches the list of courses available on iSchool+ for the current user.
  ///
  /// Returns course references that can be passed to [getStudents],
  /// [getMaterials], and [getMaterial]. Not all courses from the course
  /// system will be present — internships and newly added courses may
  /// not appear until they are set up on I-School Plus.
  ///
  /// The returned list preserves the order from the I-School Plus sidebar.
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
      if (internalId == null) continue;

      // Extract course number from the end of the option text
      final text = option.text;
      final underscoreIdx = text.lastIndexOf('_');
      if (underscoreIdx == -1) continue;
      final courseNumber = text.substring(underscoreIdx + 1);

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

  /// Fetches the list of students enrolled in the specified course.
  ///
  /// Returns student information (ID and name) for all students enrolled in
  /// the given [course].
  ///
  /// The [course] should be obtained from [getCourseList].
  ///
  /// System accounts (e.g., "istudyoaa") are automatically filtered out.
  ///
  /// Throws an [Exception] if no student data exists.
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

  /// Fetches the list of course materials for the specified course.
  ///
  /// Returns references to all files and materials posted to I-School Plus
  /// for the given [course].
  ///
  /// The [course] should be obtained from [getCourseList].
  ///
  /// Each material reference includes a title and SCORM resource identifier
  /// (href) that can be passed to [getMaterial] to obtain download information.
  ///
  /// Materials are extracted from the course's SCORM manifest XML.
  /// Folder/directory items without actual files are automatically excluded.
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

  /// Fetches download information for a specific course material.
  ///
  /// Returns the direct download URL and optional referer header required to
  /// download the material file.
  ///
  /// The [material] should be obtained from [getMaterials].
  ///
  /// The download process varies by material type:
  /// - Standard files: Direct download URL
  /// - PDFs: Requires a referer URL for access
  /// - Course recordings: Returns iStream URL with `streamable: true`
  ///
  /// When the returned [MaterialDto] has a non-null `referer` field, it must
  /// be included as the Referer header when downloading the file.
  ///
  /// Throws an [Exception] if the material cannot be accessed or parsed.
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
