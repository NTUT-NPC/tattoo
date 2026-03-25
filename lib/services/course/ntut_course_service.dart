import 'package:collection/collection.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/services/course/course_service.dart';
import 'package:tattoo/utils/http.dart';

/// English names parsed from the English course system for a single course.
typedef _EnglishCourseNames = ({
  String? number,
  String? courseName,
  String? teacherName,
  List<ReferenceDto> classes,
});

class NtutCourseService implements CourseService {
  late final Dio _courseDio;

  NtutCourseService() {
    _courseDio = createDio()
      ..options.baseUrl = 'https://aps.ntut.edu.tw/course/'
      ..interceptors.add(_SessionCheckInterceptor());
  }

  @override
  Future<List<SemesterDto>> getCourseSemesterList() async {
    final response = await _courseDio.get('tw/Select.jsp');

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

  @override
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
      null => <_EnglishCourseNames>[],
    };

    // Merge English names into Chinese-parsed DTOs. Match by course number
    // for numbered courses; for numberless rows (e.g. 班週會) fall back to
    // positional matching among the numberless subset.
    final enByNumber = <String, _EnglishCourseNames>{
      for (final en in englishNames) ?en.number: en,
    };
    final enNumberless = englishNames.where((e) => e.number == null).toList();
    var numberlessIndex = 0;

    return courses.map((dto) {
      final en = dto.number != null
          ? enByNumber[dto.number]
          : enNumberless.elementAtOrNull(numberlessIndex++);
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

    // Build schedule map keyed by course name from the grid
    final periodRegex = RegExp(r'第 (\S) 節');
    final eClassroomRegex = RegExp(r'\s*\(?e\)?\s*$');
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

        // Key by course name — works for both regular courses (with <a>
        // links) and special entries like 班週會 (plain text).
        final courseName = anchors.isNotEmpty
            ? anchors[0].text.trim()
            : cells[colIndex].text.trim();
        if (courseName.isEmpty) continue;

        var classroomRef = anchors.length >= 3
            ? _parseAnchorRef(anchors[2])
            : null;
        // Strip e化教室 marker "(e)" from classroom names
        if (classroomRef?.name case final name?) {
          classroomRef = (
            id: classroomRef!.id,
            name: name.replaceFirst(eClassroomRegex, ''),
          );
        }

        scheduleMap.putIfAbsent(courseName, () => []);
        scheduleMap[courseName]!.add((
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

      // Look up schedule+classroom from the timetable grid by course name
      final schedule = scheduleMap[course.name];

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

  /// Parses the English course list page for English names.
  ///
  /// Each entry includes the course number so callers can match by number.
  /// Numberless rows (e.g. Class Meeting) are matched positionally.
  List<_EnglishCourseNames> _parseEnCourseTable(String html) {
    final document = parse(html);
    final tables = document.querySelectorAll('table');
    if (tables.length < 2) return [];

    final tableRows = tables[1].querySelectorAll('tr');
    if (tableRows.length < 2) return [];
    // English table has 1 header row (Chinese table has 2 — student info is in
    // a separate table here). Last row is the "Total" summary.
    final dataRows = tableRows.sublist(1, tableRows.length - 1);

    return dataRows.map((row) {
      final cells = row.children;

      final number = cells.isNotEmpty ? _parseCellText(cells[0]) : null;
      final courseName = cells.length > 1 ? _parseCellText(cells[1]) : null;
      final teacherName = cells.length > 4 ? _parseCellText(cells[4]) : null;
      final classes = cells.length > 5
          ? cells[5].querySelectorAll('a').map(_parseAnchorRef).toList()
          : <ReferenceDto>[];

      return (
        number: number,
        courseName: courseName,
        teacherName: teacherName,
        classes: classes,
      );
    }).toList();
  }

  @override
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

  @override
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

  @override
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

  @override
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

/// Detects expired sessions in CourseService responses.
///
/// NTUT returns HTTP 200 with a short error message instead of a proper 401
/// when the SSO session has expired.
class _SessionCheckInterceptor extends Interceptor {
  static const _markers = ['尚未登錄入口網站', '應用系統連線已逾時'];

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is String && _markers.any(data.contains)) {
      throw const SessionExpiredException(
        'CourseService session expired',
      );
    }
    handler.next(response);
  }
}
