import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/utils/http.dart';
import 'package:collection/collection.dart';

typedef ReferenceDTO = ({String? id, String? name});

typedef SemesterDTO = ({int? year, int? semester});

typedef ScheduleDTO = ({
  String? number,
  ReferenceDTO? course,
  double? credits,
  int? hours,
  CourseType? type,
  ReferenceDTO? teacher,
  List<ReferenceDTO>? classes,
  List<(DayOfWeek, Period)>? schedule,
  ReferenceDTO? classroom,
  String? status,
  String? language,
  String? syllabusId,
  String? remarks,
});

typedef CourseDTO = ({
  String? id,
  String? nameZh,
  String? nameEn,
  double? credits,
  int? hours,
  String? descriptionZh,
  String? descriptionEn,
});

class CourseService {
  late final Dio _courseDio;

  CourseService() {
    _courseDio = createDio()
      ..options.baseUrl = 'https://aps.ntut.edu.tw/course/tw/';
  }

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
      final credits = double.tryParse(cells[3].text.trim());
      final hours = int.tryParse(cells[4].text.trim());
      final type = CourseType.values.firstWhereOrNull(
        (e) => e.name == _parseCellText(cells[5]),
      );
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

    // Second row containes id, name, credits, hours
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
}
