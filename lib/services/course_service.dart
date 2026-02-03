import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/utils/http.dart';
import 'package:collection/collection.dart';

/// Reference to an entity (course, teacher, classroom, etc.) with an ID and name.
typedef ReferenceDTO = ({
  /// Entity's unique identifier code.
  String? id,

  /// Entity's display name.
  String? name,
});

/// Academic semester identifier.
typedef SemesterDTO = ({
  /// Academic year in ROC calendar (e.g., 114 for 2025).
  int? year,

  /// Semester number (1 for fall, 2 for spring, 3 for summer).
  int? semester,
});

/// Course schedule entry from the course selection system.
typedef ScheduleDTO = ({
  /// Course offering number (e.g., "313146", "352902").
  String? number,

  /// Reference to the course.
  ReferenceDTO? course,

  /// Course sequence phase/stage number (階段, e.g., "1", "2").
  int? phase,

  /// Number of credits for this course.
  double? credits,

  /// Number of hours per week.
  int? hours,

  /// Type of course for graduation requirements.
  CourseType? type,

  /// Reference to the instructor.
  ReferenceDTO? teacher,

  /// List of class/program references this course belongs to.
  List<ReferenceDTO>? classes,

  /// Weekly schedule as list of (day, period) tuples.
  List<(DayOfWeek, Period)>? schedule,

  /// Reference to the classroom location.
  ReferenceDTO? classroom,

  /// Enrollment status for special cases (e.g., "撤選" for withdrawal).
  ///
  /// Normally null for regular enrolled courses.
  String? status,

  /// Language of instruction.
  String? language,

  /// Syllabus identifier for fetching course syllabus.
  String? syllabusId,

  /// Additional remarks or notes about the course.
  String? remarks,
});

/// Course information from the course catalog.
typedef CourseDTO = ({
  /// Course's unique identifier code.
  String? id,

  /// Course name in Traditional Chinese.
  String? nameZh,

  /// Course name in English.
  String? nameEn,

  /// Number of credits.
  double? credits,

  /// Number of hours per week.
  int? hours,

  /// Course description in Traditional Chinese.
  String? descriptionZh,

  /// Course description in English.
  String? descriptionEn,
});

/// Service for accessing NTUT's course selection and catalog system.
///
/// This service provides access to:
/// - Student course schedules and enrollment
/// - Course catalog information
/// - Teacher, classroom, and syllabus data
///
/// Authentication is required through [PortalService.sso] with
/// [PortalServiceCode.courseService] before using this service.
///
/// Data is parsed from HTML pages as NTUT does not provide a REST API.
class CourseService {
  late final Dio _courseDio;

  CourseService() {
    _courseDio = createDio()
      ..options.baseUrl = 'https://aps.ntut.edu.tw/course/tw/';
  }

  /// Fetches the list of available semesters for a student's course schedule.
  ///
  /// Returns a list of semester identifiers (year and semester number) for which
  /// course schedules are available for the given [username] (student ID).
  ///
  /// This method should be called before [getCourseTable] to determine which
  /// semesters have course data available.
  Future<List<SemesterDTO>> getCourseSemesterList(
    String username,
  ) async {
    final response = await _courseDio.post(
      'Select.jsp',
      data: {'code': username, 'format': '-3'},
    );

    // Find available course tables by reading anchor references
    // Document structure: table>tr>td>img+a[href]
    final document = parse(response.data);
    final tableAnchors = document.querySelectorAll('table a[href]');
    final tableLinks = tableAnchors.map((e) => e.attributes['href']).toList();

    // Parse links and extract query parameters
    // Link format: Select.jsp?format=-2&code=111360109&year=114&sem=1
    return tableLinks.map((link) {
      final queryParams = Uri.parse(link!).queryParameters;
      return (
        year: int.parse(queryParams['year']!),
        semester: int.parse(queryParams['sem']!),
      );
    }).toList();
  }

  /// Fetches the course schedule table for a specific student and semester.
  ///
  /// Returns a list of course offerings enrolled by the student, including:
  /// - Course details (name, credits, hours)
  /// - Schedule information (days, periods, classroom)
  /// - Teacher and class information
  /// - Enrollment status and remarks
  ///
  /// The [username] should be a student ID, and [semester] should be obtained
  /// from [getCourseSemesterList].
  ///
  /// Throws an [Exception] if no courses are found for the given semester.
  Future<List<ScheduleDTO>> getCourseTable({
    required String username,
    required SemesterDTO semester,
  }) async {
    final response = await _courseDio.get(
      'Select.jsp',
      queryParameters: {
        'format': '-2',
        'code': username,
        'year': semester.year,
        'sem': semester.semester,
      },
    );

    final document = parse(response.data);

    // There are two tables in the document; the first one is a timetable grid
    // The second table is a list with one course per row, we'll extract that
    final courseSelectionTable = document.querySelectorAll('table')[1];

    // Find all rows except the first two header rows and the last summary row
    final tableRows = courseSelectionTable.querySelectorAll('tr');
    final trimmedTableRows = tableRows.sublist(2, tableRows.length - 1);
    if (trimmedTableRows.isEmpty) {
      throw Exception('No courses found in the selection table.');
    }

    return trimmedTableRows.map((row) {
      final cells = row.children;

      // Extract basic course information
      final number = _parseCellText(cells[0]);
      final course = _parseCellRef(cells[1]);
      final phase = int.tryParse(cells[2].text.trim());
      final credits = double.tryParse(cells[3].text.trim());
      final hours = int.tryParse(cells[4].text.trim());
      final type = _parseCourseType(cells[5]);
      final teacher = _parseCellRef(cells[6]);
      final classes = _parseCellRefs(cells[7]);

      // Parse schedule from day columns (indices 8-14)
      final schedule = <(DayOfWeek, Period)>[];
      final days = DayOfWeek.values;

      for (var i = 0; i < days.length; i++) {
        final dayText = _parseCellText(cells[8 + i]);
        if (dayText == null) continue;

        // Parse period codes (e.g., "7 8" or "8 9 A") and skip invalid ones
        final periods = dayText
            .split(' ')
            .map(
              (e) => Period.values.firstWhereOrNull((p) => p.code == e.trim()),
            )
            .whereType<Period>()
            .toList();
        final scheduleOfDay = periods.map((p) => (days[i], p));
        schedule.addAll(scheduleOfDay);
      }

      final classroom = _parseCellRef(cells[15]);
      final status = _parseCellText(cells[16]);
      final language = _parseCellText(cells[17]);
      final syllabusId = _parseCellRef(cells[18]).id;
      final remarks = _parseCellText(cells[19]);

      return (
        number: number,
        course: course,
        phase: phase,
        credits: credits,
        hours: hours,
        type: type,
        teacher: teacher,
        classes: classes,
        schedule: schedule.isEmpty ? null : schedule,
        classroom: classroom,
        status: status,
        language: language,
        syllabusId: syllabusId,
        remarks: remarks,
      );
    }).toList();
  }

  /// Fetches detailed information about a specific course from the catalog.
  ///
  /// Returns course details including bilingual names, descriptions, credits,
  /// and hours per week.
  ///
  /// The [courseId] should be a course code obtained from the `course.id` field
  /// of a [ScheduleDTO].
  ///
  /// Throws an [Exception] if the course details table is not found.
  Future<CourseDTO> getCourse(String courseId) async {
    final response = await _courseDio.get(
      'Curr.jsp',
      queryParameters: {'format': '-2', 'code': courseId},
    );

    final document = parse(response.data);
    final table = document.querySelector('table');
    if (table == null) {
      throw Exception('Course details table not found.');
    }

    final tableRows = table.querySelectorAll('tr');

    // Second row contains id, name, credits, hours
    final secondRowCells = tableRows[1].children;
    final id = _parseCellText(secondRowCells[0]);
    final nameZh = _parseCellText(secondRowCells[1]);
    final nameEn = _parseCellText(secondRowCells[2]);
    final credits = double.tryParse(secondRowCells[3].text.trim());
    final hours = int.tryParse(secondRowCells[4].text.trim());

    // Second column of the third and fourth rows contain description
    final descriptionZh = _parseCellText(tableRows[2].children[1]);
    final descriptionEn = _parseCellText(tableRows[3].children[1]);

    return (
      id: id,
      nameZh: nameZh,
      nameEn: nameEn,
      credits: credits,
      hours: hours,
      descriptionZh: descriptionZh,
      descriptionEn: descriptionEn,
    );
  }

  /// Fetches detailed information about a specific teacher.
  ///
  /// Returns teacher profile information for the given [teacherId] in a specific
  /// [semester].
  ///
  /// This method is not yet implemented.
  Future getTeacher({
    required String teacherId,
    required SemesterDTO semester,
  }) async {
    await _courseDio.get(
      'Teach.jsp',
      queryParameters: {
        'format': '-3',
        'year': semester.year,
        'sem': semester.semester,
        'code': teacherId,
      },
    );

    throw UnimplementedError();
  }

  /// Fetches detailed information about a specific classroom.
  ///
  /// Returns classroom information including location and schedule for the given
  /// [classroomId] in a specific [semester].
  ///
  /// This method is not yet implemented.
  Future getClassroom({
    required String classroomId,
    required SemesterDTO semester,
  }) async {
    await _courseDio.get(
      'Croom.jsp',
      queryParameters: {
        'format': '-3',
        'year': semester.year,
        'sem': semester.semester,
        'code': classroomId,
      },
    );

    throw UnimplementedError();
  }

  /// Fetches the detailed syllabus for a course offering.
  ///
  /// Returns syllabus information including course objectives, textbooks,
  /// grading policy, and weekly schedule.
  ///
  /// The [courseNumber] should be a course offering number (e.g., "313146"),
  /// and [id] should be the syllabus ID from the `syllabusId` field of a
  /// [ScheduleDTO].
  ///
  /// This method is not yet implemented.
  Future getSyllabus({
    required String courseNumber,
    required String id,
  }) async {
    await _courseDio.get(
      'ShowSyllabus.jsp',
      queryParameters: {'snum': courseNumber, 'code': id},
    );

    throw UnimplementedError();
  }

  String? _parseCellText(Element cell) {
    final text = cell.text.trim();
    return text.isNotEmpty ? text : null;
  }

  ReferenceDTO _parseCellRef(Element cell) {
    final name = _parseCellText(cell);
    if (name == null) return (id: null, name: null);
    final href = cell.querySelector('a')?.attributes['href'];
    if (href == null) return (id: null, name: name);
    final code = Uri.parse(href).queryParameters['code'];
    return (id: code, name: name);
  }

  List<ReferenceDTO>? _parseCellRefs(Element cell) {
    final anchors = cell.querySelectorAll('a');
    if (anchors.isEmpty) return null;

    ReferenceDTO toReference(Element anchor) {
      final name = anchor.text.trim();
      final href = anchor.attributes['href'];
      if (href == null) return (id: null, name: name);
      final code = Uri.parse(href).queryParameters['code'];
      return (id: code, name: name);
    }

    final refs = anchors.map(toReference).toList();
    return refs.isNotEmpty ? refs : null;
  }

  CourseType? _parseCourseType(Element cell) {
    final text = _parseCellText(cell);
    switch (text) {
      case '必':
        return CourseType.required;
      case '選':
        return CourseType.elective;
      case '通':
        return CourseType.general;
      default:
        return null;
    }
  }
}
