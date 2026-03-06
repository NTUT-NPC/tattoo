import 'package:collection/collection.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/utils/http.dart';

/// Course schedule entry from the course selection system.
typedef ScheduleDto = ({
  /// Course offering number (e.g., "313146", "352902").
  String? number,

  /// Reference to the course with bilingual name.
  LocalizedRefDto? course,

  /// Course sequence phase/stage number (階段, e.g., "1", "2").
  int? phase,

  /// Number of credits for this course.
  double? credits,

  /// Number of hours per week.
  int? hours,

  /// Type of course (e.g., "必", "選", "通", "輔").
  String? type,

  /// Reference to the instructor with bilingual name.
  LocalizedRefDto? teacher,

  /// List of class/program references with bilingual names.
  List<LocalizedRefDto>? classes,

  /// Weekly schedule as list of (day, period, classroom) entries.
  ///
  /// Each entry includes the classroom for that specific timeslot, as some
  /// courses use different rooms for different sessions.
  List<({DayOfWeek day, Period period, ReferenceDto? classroom})>? schedule,

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
typedef CourseDto = ({
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
typedef OfficeHourDto = ({
  /// Day of week.
  DayOfWeek day,

  /// Start time as (hour, minute).
  ({int hour, int minute}) startTime,

  /// End time as (hour, minute).
  ({int hour, int minute}) endTime,
});

/// Teacher profile information from the teacher schedule page.
typedef TeacherDto = ({
  /// Reference to the teacher's department.
  ReferenceDto? department,

  /// Academic title (e.g., "專任副教授", "兼任講師").
  String? title,

  /// Teacher's name in Traditional Chinese.
  String? nameZh,

  /// Teacher's name in English (from office hours page).
  String? nameEn,

  /// Total teaching hours for the semester.
  double? teachingHours,

  /// Office hours time slots.
  List<OfficeHourDto>? officeHours,

  /// Additional notes about office hours (e.g., appointment requirements).
  String? officeHoursNote,
});

/// Syllabus details from the course syllabus page (教學大綱與進度).
typedef SyllabusDto = ({
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

/// English names parsed from the English course system for a single course.
typedef _EnglishCourseNames = ({
  String? courseName,
  String? teacherName,
  List<ReferenceDto> classes,
});

/// Provides the singleton [CourseService] instance.
final courseServiceProvider = Provider<CourseService>((ref) => CourseService());

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
      ..options.baseUrl = 'https://aps.ntut.edu.tw/course/';
  }

  /// Fetches the list of available semesters for a student's course schedule.
  ///
  /// Returns a list of semester identifiers (year and semester number) for which
  /// course schedules are available for the given [username] (student ID).
  ///
  /// This method should be called before [getCourseTable] to determine which
  /// semesters have course data available.
  Future<List<SemesterDto>> getCourseSemesterList(
    String username,
  ) async {
    final response = await _courseDio.post(
      'tw/Select.jsp',
      data: {'code': username, 'format': '-3'},
    );

    // Find available course tables by reading anchor references
    // Document structure: table>tr>td>img+a[href]
    final document = parse(response.data);
    final tableAnchors = document.querySelectorAll('table a[href]');
    final tableLinks = tableAnchors
        .map((e) => e.attributes['href'])
        .nonNulls
        .toList();

    // Parse links and extract query parameters
    // Link format: Select.jsp?format=-2&code=111360109&year=114&sem=1
    return tableLinks.map((link) {
      final queryParams = Uri.parse(link).queryParameters;
      return (
        year: int.tryParse(queryParams['year'] ?? ''),
        term: int.tryParse(queryParams['sem'] ?? ''),
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
  Future<List<ScheduleDto>> getCourseTable({
    required String username,
    required SemesterDto semester,
  }) async {
    final queryParameters = {
      'format': '-2',
      'code': username,
      'year': semester.year,
      'sem': semester.term,
    };

    // Fetch Chinese and English pages in parallel
    final (zhResponse, enResponse) = await (
      _courseDio.get('tw/Select.jsp', queryParameters: queryParameters),
      _courseDio
          .get('en/Select.jsp', queryParameters: queryParameters)
          .then<Response?>((r) => r, onError: (_) => null),
    ).wait;

    final courses = _parseZhCourseTable(zhResponse.data);
    final englishNames = switch (enResponse) {
      final r? => _parseEnCourseTable(r.data),
      null => <String, _EnglishCourseNames>{},
    };

    // Merge English names into Chinese-parsed DTOs
    return courses.map((dto) {
      final en = englishNames[dto.number];
      if (en == null) return dto;
      return (
        number: dto.number,
        course: (
          id: dto.course?.id,
          nameZh: dto.course?.nameZh,
          nameEn: en.courseName,
        ),
        phase: dto.phase,
        credits: dto.credits,
        hours: dto.hours,
        type: dto.type,
        teacher: (
          id: dto.teacher?.id,
          nameZh: dto.teacher?.nameZh,
          nameEn: en.teacherName,
        ),
        classes: dto.classes
            ?.map(
              (c) => (
                id: c.id,
                nameZh: c.nameZh,
                nameEn: en.classes.firstWhereOrNull((e) => e.id == c.id)?.name,
              ),
            )
            .toList(),
        schedule: dto.schedule,
        status: dto.status,
        language: dto.language,
        syllabusId: dto.syllabusId,
        remarks: dto.remarks,
      );
    }).toList();
  }

  /// Parses the Chinese course table page (timetable grid + course list).
  ///
  /// Returns [ScheduleDto]s with `nameEn: null` — English names are merged
  /// separately from the English page.
  List<ScheduleDto> _parseZhCourseTable(String html) {
    final document = parse(html);
    final tables = document.querySelectorAll('table');
    if (tables.length < 2) {
      throw Exception('Expected timetable grid and course list tables.');
    }

    // Parse the timetable grid (table[0]) for per-timeslot schedule+classroom
    // Structure: header row has day labels (一–日), data rows have period
    // labels in column 0 and course cells with <a> links for the rest.
    final timetableGrid = tables[0];
    final timetableRows = timetableGrid.querySelectorAll('tr');
    if (timetableRows.length < 3) {
      throw Exception('Timetable grid has no data rows.');
    }

    // Build column -> DayOfWeek map from header row
    const dayCharToEnum = {
      '一': DayOfWeek.monday,
      '二': DayOfWeek.tuesday,
      '三': DayOfWeek.wednesday,
      '四': DayOfWeek.thursday,
      '五': DayOfWeek.friday,
      '六': DayOfWeek.saturday,
      '日': DayOfWeek.sunday,
    };
    final headerCells = timetableRows[1].children;
    final colToDayMap = <int, DayOfWeek>{};
    for (var i = 1; i < headerCells.length; i++) {
      final text = headerCells[i].text.trim();
      final day = dayCharToEnum.entries
          .firstWhereOrNull((e) => text.contains(e.key))
          ?.value;
      if (day != null) colToDayMap[i] = day;
    }

    // Build schedule map keyed by course ID from the grid
    final periodRegex = RegExp(r'第 (\S) 節');
    final scheduleMap =
        <
          String,
          List<({DayOfWeek day, Period period, ReferenceDto? classroom})>
        >{};

    for (var rowIndex = 2; rowIndex < timetableRows.length; rowIndex++) {
      final cells = timetableRows[rowIndex].children;
      if (cells.isEmpty) continue;

      final periodMatch = periodRegex.firstMatch(cells[0].text);
      if (periodMatch == null) continue;
      final period = Period.values.firstWhereOrNull(
        (p) => p.code == periodMatch.group(1),
      );
      if (period == null) continue;

      for (var colIndex = 1; colIndex < cells.length; colIndex++) {
        final day = colToDayMap[colIndex];
        if (day == null) continue;

        final anchors = cells[colIndex].querySelectorAll('a');
        if (anchors.isEmpty) continue;

        final courseRef = _parseAnchorRef(anchors[0]);
        final courseId = courseRef.id;
        if (courseId == null) continue;

        final classroomRef = anchors.length >= 3
            ? _parseAnchorRef(anchors[2])
            : null;

        scheduleMap.putIfAbsent(courseId, () => []);
        scheduleMap[courseId]!.add((
          day: day,
          period: period,
          classroom: classroomRef,
        ));
      }
    }

    // Parse the course list (table[1]) for metadata
    final courseListTable = tables[1];
    final tableRows = courseListTable.querySelectorAll('tr');
    final trimmedTableRows = tableRows.sublist(2, tableRows.length - 1);
    if (trimmedTableRows.isEmpty) {
      throw Exception('No courses found in the selection table.');
    }

    return trimmedTableRows.map((row) {
      final cells = row.children;

      final number = _parseCellText(cells[0]);
      final course = _parseCellRef(cells[1]);
      final phase = int.tryParse(cells[2].text.trim());
      final credits = double.tryParse(cells[3].text.trim());
      final hours = int.tryParse(cells[4].text.trim());
      final type = _parseCellText(cells[5]);
      final teacher = _parseCellRef(cells[6]); // TODO: Handle multiple teachers
      final classes = _parseCellRefs(cells[7]);

      // Look up schedule+classroom from the timetable grid by course ID
      final schedule = course.id != null ? scheduleMap[course.id!] : null;

      final status = _parseCellText(cells[16]);
      final language = _parseCellText(cells[17]);
      final syllabusId = _parseCellRef(cells[18]).id;
      final remarks = _parseCellText(cells[19]);

      return (
        number: number,
        course: (id: course.id, nameZh: course.name, nameEn: null),
        phase: phase,
        credits: credits,
        hours: hours,
        type: type,
        teacher: (id: teacher.id, nameZh: teacher.name, nameEn: null),
        classes: classes
            ?.map<LocalizedRefDto>(
              (c) => (id: c.id, nameZh: c.name, nameEn: null),
            )
            .toList(),
        schedule: schedule,
        status: status,
        language: language,
        syllabusId: syllabusId,
        remarks: remarks,
      );
    }).toList();
  }

  /// Parses the English course list page into a map keyed by course number.
  Map<String, _EnglishCourseNames> _parseEnCourseTable(String html) {
    final document = parse(html);
    final tables = document.querySelectorAll('table');
    if (tables.length < 2) return {};

    final tableRows = tables[1].querySelectorAll('tr');
    if (tableRows.length < 3) return {};
    final dataRows = tableRows.sublist(2, tableRows.length - 1);

    // Parse the table and build a map of course number -> English names
    // Columns existed in the Chinese page are skipped
    final map = <String, _EnglishCourseNames>{};
    for (final row in dataRows) {
      final cells = row.children;
      if (cells.length < 6) continue;
      final number = _parseCellText(cells[0]);
      if (number == null) continue;

      final courseName = _parseCellText(cells[1]);
      final teacherName = _parseCellText(cells[4]);
      final classes = cells[5]
          .querySelectorAll('a')
          .map(_parseAnchorRef)
          .toList();

      map[number] = (
        courseName: courseName,
        teacherName: teacherName,
        classes: classes,
      );
    }

    return map;
  }

  /// Fetches detailed information about a specific course from the catalog.
  ///
  /// Returns course details including bilingual names, descriptions, credits,
  /// and hours per week.
  ///
  /// The [courseId] should be a course code obtained from the `course.id` field
  /// of a [ScheduleDto].
  ///
  /// Throws an [Exception] if the course details table is not found.
  Future<CourseDto> getCourse(String courseId) async {
    final response = await _courseDio.get(
      'tw/Curr.jsp',
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
  /// field of a [ScheduleDto].
  Future<TeacherDto> getTeacher({
    required String teacherId,
    required SemesterDto semester,
  }) async {
    final queryParams = {
      'year': semester.year,
      'sem': semester.term,
      'code': teacherId,
    };

    final (profileResponse, officeHoursResponse) = await (
      _courseDio.get(
        'tw/Teach.jsp',
        queryParameters: {'format': '-3', ...queryParams},
      ),
      _courseDio.get(
        'tw/Teach.jsp',
        queryParameters: {'format': '-6', ...queryParams},
      ),
    ).wait;

    // Parse format=-3: profile header
    // Structure: <th colspan="24"><a>dept</a> title name hours <a>office hours link</a></th>
    final profileDoc = parse(profileResponse.data);
    final headerTh = profileDoc.querySelector('table tr:first-child th');

    ReferenceDto? department;
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
    final officeHours = <OfficeHourDto>[];
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
    required SemesterDto semester,
  }) async {
    await _courseDio.get(
      'tw/Croom.jsp',
      queryParameters: {
        'format': '-3',
        'year': semester.year,
        'sem': semester.term,
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
  /// [ScheduleDto].
  ///
  /// Throws an [Exception] if the syllabus tables are not found.
  Future<SyllabusDto> getSyllabus({
    required String courseNumber,
    required String syllabusId,
  }) async {
    final response = await _courseDio.get(
      'tw/ShowSyllabus.jsp',
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

  ReferenceDto _parseAnchorRef(Element anchor) {
    final name = anchor.text.trim();
    final href = anchor.attributes['href'];
    if (href == null) return (id: null, name: name.isNotEmpty ? name : null);
    final code = Uri.parse(href).queryParameters['code'];
    return (id: code, name: name.isNotEmpty ? name : null);
  }

  ReferenceDto _parseCellRef(Element cell) {
    final name = _parseCellText(cell);
    if (name == null) return (id: null, name: null);
    final href = cell.querySelector('a')?.attributes['href'];
    if (href == null) return (id: null, name: name);
    final code = Uri.parse(href).queryParameters['code'];
    return (id: code, name: name);
  }

  List<ReferenceDto>? _parseCellRefs(Element cell) {
    final anchors = cell.querySelectorAll('a');
    if (anchors.isEmpty) return null;

    ReferenceDto toReference(Element anchor) {
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
