import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/models/i_school_plus.dart';
import 'package:tattoo/utils/http.dart';

class ISchoolPlusClient {
  late final Dio _iSchoolPlusDio;

  /// A [CourseSchedule.number] of the selected course.
  ///
  /// All operations in this client will pertain to this course.
  String? _selectedCourseNumber;

  ISchoolPlusClient() {
    _iSchoolPlusDio = createDio()
      ..options.baseUrl = 'https://istudy.ntut.edu.tw/learn/'
      ..interceptors.insert(0, InvalidCookieFilter()); // Prepend cookie filter
  }

  Future<void> _selectCourse(String courseNumber) async {
    if (courseNumber == _selectedCourseNumber) return;

    // Fetch the sidebar page for a list of courses
    final response = await _iSchoolPlusDio.get('mooc_sysbar.php');

    // Parse the HTML to find the course selection dropdown
    final document = parse(response.data);
    final courseSelect = document.getElementById('selcourse');
    if (courseSelect == null) {
      throw Exception('No courses found for the user.');
    }

    // Find the internal ID for the given course number
    // Example option: <option value="10099386">1141_智慧財產權_352902</option>
    // We match the course number (352902) for the option value (10099386).
    final internalCourseId = courseSelect.children
        .firstWhere(
          (option) => option.text.contains(courseNumber),
          orElse: () => throw Exception('Course $courseNumber not found.'),
        )
        .attributes['value'];
    if (internalCourseId == null) {
      throw Exception('Course $courseNumber not found.');
    }

    // Send request to select the course
    await _iSchoolPlusDio.post(
      'goto_course.php',
      data:
          '<manifest><ticket/><course_id>$internalCourseId</course_id><env/></manifest>',
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    _selectedCourseNumber = courseNumber;
  }

  /// Fetches the list of students enrolled in the specified [courseNumber].
  Future<List<ISchoolPlusStudent>> getStudents(String courseNumber) async {
    await _selectCourse(courseNumber);

    final response = await _iSchoolPlusDio.get('learn_ranking.php');

    // Parse the HTML and extract the table of student rankings
    final document = parse(response.data);
    final studyRankingsTable = document.querySelector('.content>.data2 tbody');
    if (studyRankingsTable == null) {
      throw Exception('No student data found for course $courseNumber.');
    }

    // Extract second column from each row for student ID and name
    // Example cell: "111360109 (何承軒)"
    final students = studyRankingsTable.children
        .map((row) => row.children[1].children.first.text)
        .toList();
    if (students.isEmpty) {
      throw Exception('No students found for course $courseNumber.');
    }

    return students
        .map((student) {
          final parts = student.split(' (');
          final id = parts[0];
          final name = parts[1].replaceAll(')', '').trim();

          return ISchoolPlusStudent(
            id: id.isEmpty ? null : id,
            name: name.isEmpty ? null : name,
          );
        })
        .where(
          (student) => student.id != 'istudyoaa', // Filter out system account
        )
        .toList();
  }

  /// Fetches the list of files/materials for the specified [courseNumber].
  Future<List<ISchoolPlusMaterialRef>> getMaterials(String courseNumber) async {
    await _selectCourse(courseNumber);

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

      return ISchoolPlusMaterialRef(title: title, href: href);
    }).toList();
  }
}
