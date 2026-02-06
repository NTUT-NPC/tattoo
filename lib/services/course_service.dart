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

  /// Type of course (e.g., "必", "選", "通", "輔").
  String? type,

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

/// Office hours time slot for a teacher.
typedef OfficeHourDTO = ({
  /// Day of week.
  DayOfWeek day,

  /// Start time as (hour, minute).
  ({int hour, int minute}) startTime,

  /// End time as (hour, minute).
  ({int hour, int minute}) endTime,
});

/// Teacher profile information from the teacher schedule page.
typedef TeacherDTO = ({
  /// Reference to the teacher's department.
  ReferenceDTO? department,

  /// Academic title (e.g., "專任副教授", "兼任講師").
  String? title,

  /// Teacher's name in Traditional Chinese.
  String? nameZh,

  /// Teacher's name in English (from office hours page).
  String? nameEn,

  /// Total teaching hours for the semester.
  double? teachingHours,

  /// Office hours time slots.
  List<OfficeHourDTO>? officeHours,

  /// Additional notes about office hours (e.g., appointment requirements).
  String? officeHoursNote,
});

/// Syllabus details from the course syllabus page (教學大綱與進度).
typedef SyllabusDTO = ({
  // Header table (課程基本資料)

  /// Course type for graduation requirements (修).
  ///
  /// More accurate than course table types (必/選/通/輔).
  /// Uses symbols: ○, △, ☆, ●, ▲, ★
  CourseType? type,

  /// Number of enrolled students (人).
  int? enrolled,

  /// Number of withdrawn students (撤).
  int? withdrawn,

  // Syllabus table (教學大綱與進度)

  /// Instructor's email address.
  String? email,

  /// Last updated timestamp (最後更新時間).
  DateTime? lastUpdated,

  /// Course objective/outline (課程大綱).
  ///
  /// English page: "Course Objective"
  String? objective,

  /// Weekly plan (課程進度).
  ///
  /// English page: "Course Schedule" - describes weekly topics, not class
  /// meeting times.
  String? weeklyPlan,

  /// Evaluation and grading policy (評量方式與標準).
  String? evaluation,

  /// Textbooks and reference materials (使用教材、參考書目或其他).
  String? materials,

  /// Additional remarks (備註).
  String? remarks,
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
      final type = _parseCellText(cells[5]);
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
  /// Returns teacher profile information including department, title, and
  /// office hours for the given [teacherId] in a specific [semester].
  ///
  /// The [teacherId] should be a teacher code obtained from the `teacher.id`
  /// field of a [ScheduleDTO].
  Future<TeacherDTO> getTeacher({
    required String teacherId,
    required SemesterDTO semester,
  }) async {
    final queryParams = {
      'year': semester.year,
      'sem': semester.semester,
      'code': teacherId,
    };

    final (profileResponse, officeHoursResponse) = await (
      _courseDio.get(
        'Teach.jsp',
        queryParameters: {'format': '-3', ...queryParams},
      ),
      _courseDio.get(
        'Teach.jsp',
        queryParameters: {'format': '-6', ...queryParams},
      ),
    ).wait;

    // Parse format=-3: profile header
    // Structure: <th colspan="24"><a>dept</a> title name hours <a>office hours link</a></th>
    final profileDoc = parse(profileResponse.data);
    final headerTh = profileDoc.querySelector('table tr:first-child th');

    ReferenceDTO? department;
    String? title;
    String? nameZh;
    double? teachingHours;

    if (headerTh != null) {
      final anchors = headerTh.querySelectorAll('a');
      if (anchors.isNotEmpty) {
        final deptAnchor = anchors.first;
        final deptHref = deptAnchor.attributes['href'];
        final deptCode = deptHref != null
            ? Uri.parse(deptHref).queryParameters['code']
            : null;
        department = (id: deptCode, name: deptAnchor.text.trim());
      }

      // Parse text segments: "dept  title  name  XX.XX 小時  office hours link"
      final fullText = headerTh.text.trim();
      final segments = fullText
          .split(RegExp(r'\s{2,}'))
          .where((s) => s.isNotEmpty)
          .toList();

      if (segments.length >= 4) {
        title = segments[1];
        nameZh = segments[2];
        final hoursMatch = RegExp(r'([\d.]+)\s*小時').firstMatch(segments[3]);
        teachingHours = hoursMatch != null
            ? double.tryParse(hoursMatch.group(1)!)
            : null;
      }
    }

    // Parse format=-6: office hours
    // Structure: plain text with <br> separators
    final officeDoc = parse(officeHoursResponse.data);
    final bodyText = officeDoc.body?.text ?? '';
    final lines = bodyText.split(RegExp(r'\n')).map((l) => l.trim()).toList();

    String? nameEn;
    final officeHours = <OfficeHourDTO>[];
    String? officeHoursNote;

    for (final line in lines) {
      // Parse instructor line: "教師姓名(Instructor)　陸元平(Luh Yuan-Ping)"
      if (line.contains('Instructor')) {
        final nameMatch = RegExp(r'\(([A-Za-z\s\-]+)\)$').firstMatch(line);
        nameEn = nameMatch?.group(1);
      }

      // Parse office hours: "星期三(Wed)　10:00 ~ 13:00"
      final hourMatch = RegExp(
        r'星期[一二三四五六日]\((\w+)\)\s*(\d{1,2}:\d{2})\s*~\s*(\d{1,2}:\d{2})',
      ).firstMatch(line);
      if (hourMatch != null) {
        final dayCode = hourMatch.group(1)!;
        final day = _parseDayOfWeek(dayCode);
        final start = _parseTime(hourMatch.group(2)!);
        final end = _parseTime(hourMatch.group(3)!);
        if (day != null && start != null && end != null) {
          officeHours.add((day: day, startTime: start, endTime: end));
        }
      }

      // Parse note: "備　註(Note)　..."
      if (line.contains('Note)')) {
        final noteMatch = RegExp(r'Note\)\s*(.+)$').firstMatch(line);
        officeHoursNote = noteMatch?.group(1);
      }
    }

    return (
      department: department,
      title: title,
      nameZh: nameZh,
      nameEn: nameEn,
      teachingHours: teachingHours,
      officeHours: officeHours.isNotEmpty ? officeHours : null,
      officeHoursNote: officeHoursNote,
    );
  }

  DayOfWeek? _parseDayOfWeek(String code) {
    return switch (code.toLowerCase()) {
      'sun' => DayOfWeek.sunday,
      'mon' => DayOfWeek.monday,
      'tue' => DayOfWeek.tuesday,
      'wed' => DayOfWeek.wednesday,
      'thu' => DayOfWeek.thursday,
      'fri' => DayOfWeek.friday,
      'sat' => DayOfWeek.saturday,
      _ => null,
    };
  }

  ({int hour, int minute})? _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return (hour: hour, minute: minute);
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
  /// grading policy, and weekly plan.
  ///
  /// The [courseNumber] should be a course offering number (e.g., "346774"),
  /// and [syllabusId] should be obtained from the `syllabusId` field of a
  /// [ScheduleDTO].
  ///
  /// Throws an [Exception] if the syllabus tables are not found.
  Future<SyllabusDTO> getSyllabus({
    required String courseNumber,
    required String syllabusId,
  }) async {
    final response = await _courseDio.get(
      'ShowSyllabus.jsp',
      queryParameters: {'snum': courseNumber, 'code': syllabusId},
    );

    final document = parse(response.data);
    final tables = document.querySelectorAll('table');
    if (tables.length < 2) {
      throw Exception('Syllabus tables not found.');
    }

    // Table 0: Header table (課程基本資料)
    // Row 1 contains: semester, number, name, phase, credits, hours, type,
    // instructor, classes, enrolled, withdrawn, remarks
    final headerRow = tables[0].querySelectorAll('tr')[1];
    final headerCells = headerRow.querySelectorAll('td');

    final typeSymbol = _parseCellText(headerCells[6]);
    final type = CourseType.values.firstWhereOrNull(
      (t) => t.symbol == typeSymbol,
    );
    final enrolled = int.tryParse(headerCells[9].text.trim());
    final withdrawn = int.tryParse(headerCells[10].text.trim());

    // Table 1: Syllabus table (教學大綱與進度)
    // Rows 0-2: Label and value both in th elements
    // Rows 3+: Label in th, value in td (some with textarea)
    final syllabusRows = tables[1].querySelectorAll('tr');

    final email = _parseCellText(syllabusRows[1].querySelectorAll('th')[1]);
    final lastUpdatedText = _parseCellText(
      syllabusRows[2].querySelectorAll('th')[1],
    );
    final lastUpdated = DateTime.tryParse(lastUpdatedText ?? '');

    // Rows 3-5 have textarea elements for long content
    final objective = _parseTextareaValue(syllabusRows[3]);
    final weeklyPlan = _parseTextareaValue(syllabusRows[4]);
    final evaluation = _parseTextareaValue(syllabusRows[5]);
    final materials = _parseTextareaValue(syllabusRows[6]);

    final remarksTd = syllabusRows[10].querySelector('td');
    final remarks = remarksTd != null ? _parseCellText(remarksTd) : null;

    return (
      type: type,
      enrolled: enrolled,
      withdrawn: withdrawn,
      email: email,
      lastUpdated: lastUpdated,
      objective: objective,
      weeklyPlan: weeklyPlan,
      evaluation: evaluation,
      materials: materials,
      remarks: remarks,
    );
  }

  String? _parseTextareaValue(Element row) {
    final textarea = row.querySelector('textarea');
    if (textarea == null) return null;
    final text = textarea.text.trim();
    return text.isNotEmpty ? text : null;
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
}
