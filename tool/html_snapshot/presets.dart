part of '../html_snapshot.dart';

class SemesterRef {
  final int year;
  final int term;

  const SemesterRef({required this.year, required this.term});
}

class ISchoolCourseRef {
  final String courseNumber;
  final String internalId;

  const ISchoolCourseRef({
    required this.courseNumber,
    required this.internalId,
  });
}

// dart format off
enum SnapshotService {
  portal(
    cliName: 'portal',
    baseUrl: 'https://app.ntut.edu.tw/',
    host: 'app.ntut.edu.tw',
  ),
  course(
    cliName: 'course',
    baseUrl: 'https://aps.ntut.edu.tw/course/',
    host: 'aps.ntut.edu.tw',
    ssoCode: 'aa_0010-oauth',
  ),
  studentQuery(
    cliName: 'student_query',
    baseUrl: 'https://aps-stu.ntut.edu.tw/StuQuery/',
    host: 'aps-stu.ntut.edu.tw',
    ssoCode: 'sa_003_oauth',
  ),
  ischool(
    cliName: 'ischool',
    baseUrl: 'https://istudy.ntut.edu.tw/learn/',
    host: 'istudy.ntut.edu.tw',
    ssoCode: 'ischool_plus_oauth',
  );

  final String cliName;
  final String baseUrl;
  final String host;
  final String? ssoCode;

  const SnapshotService({
    required this.cliName,
    required this.baseUrl,
    required this.host,
    this.ssoCode,
  });

  static List<String> get cliNames {
    return values.map((service) => service.cliName).toList();
  }

  static List<String> get ssoCliNames {
    return values
        .where((service) => service.ssoCode != null)
        .map((service) => service.cliName)
        .toList();
  }

  static SnapshotService? byCliName(String value) {
    for (final service in values) {
      if (service.cliName == value) return service;
    }
    return null;
  }
}
// dart format on

final _presetList = <SnapshotPreset>[
  SnapshotPreset(
    name: 'portal.application_categories',
    service: .portal,
    description: 'NTUT Portal application category page.',
    includeInAll: true,
    buildRequest: _simple(.portal, 'apPopupFull.do', query: {'init': ''}),
  ),
  SnapshotPreset(
    name: 'portal.academic_applications',
    service: .portal,
    description: 'NTUT Portal academic application list.',
    includeInAll: true,
    buildRequest: _simple(
      .portal,
      'apPopupFull.do',
      query: {
        'apView': 'apMap',
        'apDn':
            'OU=aa,OU=aproot,OU=ldaproot,OU=ldapConfig,DC=campus,DC=cnc,DC=ntut,DC=edu,DC=tw',
      },
    ),
  ),
  SnapshotPreset(
    name: 'student_query.profile',
    service: .studentQuery,
    description: 'Student Query profile page.',
    includeInAll: true,
    buildRequest: _simple(.studentQuery, 'QryBasisData.jsp'),
  ),
  SnapshotPreset(
    name: 'student_query.academic_performance',
    service: .studentQuery,
    description: 'Student Query academic performance page.',
    includeInAll: true,
    buildRequest: _simple(
      .studentQuery,
      'QryScore.jsp',
      query: {'format': '-2'},
    ),
  ),
  SnapshotPreset(
    name: 'student_query.gpa',
    service: .studentQuery,
    description: 'Student Query GPA summary page.',
    includeInAll: true,
    buildRequest: _simple(.studentQuery, 'QryGPA.jsp'),
  ),
  SnapshotPreset(
    name: 'student_query.grade_ranking',
    service: .studentQuery,
    description: 'Student Query ranking page.',
    includeInAll: true,
    buildRequest: _simple(.studentQuery, 'QryRank.jsp'),
  ),
  SnapshotPreset(
    name: 'student_query.registration_records',
    service: .studentQuery,
    description: 'Student Query registration history page.',
    includeInAll: true,
    buildRequest: _simple(.studentQuery, 'QryRegist.jsp'),
  ),
  SnapshotPreset(
    name: 'course.semester_list',
    service: .course,
    description: 'Course system semester selector page.',
    includeInAll: true,
    buildRequest: _simple(.course, 'tw/Select.jsp'),
  ),
  SnapshotPreset(
    name: 'course.table_zh',
    service: .course,
    description: 'Course timetable (Chinese). Optional: --year --term.',
    includeInAll: true,
    buildRequest: _courseTable('tw/Select.jsp'),
  ),
  SnapshotPreset(
    name: 'course.table_en',
    service: .course,
    description: 'Course timetable (English). Optional: --year --term.',
    includeInAll: true,
    buildRequest: _courseTable('en/Select.jsp'),
  ),
  SnapshotPreset(
    name: 'course.detail',
    service: .course,
    description: 'Course detail page. Required: --course-id.',
    allSkipReason: 'requires --course-id',
    buildRequest: _courseRequiredId(
      path: 'tw/Curr.jsp',
      option: 'course-id',
      filePrefix: 'course',
      query: (courseId) => {'format': '-2', 'code': courseId},
    ),
  ),
  SnapshotPreset(
    name: 'course.teacher_profile',
    service: .course,
    description:
        'Teacher profile page. Required: --teacher-id. Optional: --year --term.',
    allSkipReason: 'requires --teacher-id',
    buildRequest: _courseSemesterRequiredId(
      path: 'tw/Teach.jsp',
      format: '-3',
      option: 'teacher-id',
      filePrefix: 'teacher',
    ),
  ),
  SnapshotPreset(
    name: 'course.teacher_office_hours',
    service: .course,
    description:
        'Teacher office hours page. Required: --teacher-id. Optional: --year --term.',
    allSkipReason: 'requires --teacher-id',
    buildRequest: _courseSemesterRequiredId(
      path: 'tw/Teach.jsp',
      format: '-6',
      option: 'teacher-id',
      filePrefix: 'teacher',
    ),
  ),
  SnapshotPreset(
    name: 'course.classroom',
    service: .course,
    description:
        'Classroom info page. Required: --classroom-id. Optional: --year --term.',
    allSkipReason: 'requires --classroom-id',
    buildRequest: _courseSemesterRequiredId(
      path: 'tw/Croom.jsp',
      format: '-3',
      option: 'classroom-id',
      filePrefix: 'classroom',
    ),
  ),
  SnapshotPreset(
    name: 'course.offering_header_zh',
    service: .course,
    description:
        'Course offering lookup header (Chinese). Required: --course-number.',
    allSkipReason: 'requires --course-number',
    buildRequest: _offeringHeader,
  ),
  SnapshotPreset(
    name: 'course.offering_query_zh',
    service: .course,
    description:
        'Course offering query result (Chinese). Required: --course-number.',
    allSkipReason: 'requires --course-number',
    buildRequest: _offeringQuery,
  ),

  SnapshotPreset(
    name: 'course.syllabus',
    service: .course,
    description:
        'Course syllabus page. Required: --course-number --teacher-id.',
    allSkipReason: 'requires --course-number and --teacher-id',
    buildRequest: _syllabus,
  ),
  SnapshotPreset(
    name: 'ischool.course_list',
    service: .ischool,
    description: 'iSchool+ course list page.',
    includeInAll: true,
    buildRequest: _simple(.ischool, 'mooc_sysbar.php'),
  ),
  SnapshotPreset(
    name: 'ischool.students',
    service: .ischool,
    description:
        'iSchool+ student ranking page. Optional: --course-internal-id --course-number.',
    includeInAll: true,
    buildRequest: _ischoolCoursePage('learn_ranking.php'),
  ),
  SnapshotPreset(
    name: 'ischool.materials',
    service: .ischool,
    description:
        'iSchool+ course materials page. Optional: --course-internal-id --course-number.',
    includeInAll: true,
    buildRequest: _ischoolCoursePage(
      'path/SCORM_loadCA.php',
      extension: 'xml',
    ),
  ),
];

final _presets = {for (final preset in _presetList) preset.name: preset};

typedef SnapshotRequestBuilder =
    Future<SnapshotRequest> Function(
      SnapshotContext context,
      ArgResults args,
    );

SnapshotRequestBuilder _simple(
  SnapshotService service,
  String path, {
  String extension = 'html',
  Map<String, dynamic>? query,
}) {
  return (context, args) async {
    return SnapshotRequest(
      service: service,
      path: path,
      query: query,
      extension: extension,
    );
  };
}

Future<Snapshot> _captureRequest(
  SnapshotContext context, {
  required String label,
  required SnapshotRequest request,
}) async {
  for (final beforeRequest in request.beforeRequests) {
    await context.send(beforeRequest);
  }
  final response = await context.send(request);
  return Snapshot(
    service: request.service,
    label: label,
    preset: label,
    requestUrl: _redactedRequestUrl(response.requestOptions.uri),
    body: _responseBodyAsString(response.data),
    extension: request.extension,
    fileParts: [_shortPresetName(label), ...request.fileParts],
  );
}

SnapshotRequestBuilder _courseTable(String path) {
  return (context, args) async {
    final semester = await _resolveCourseSemester(context, args);
    return SnapshotRequest(
      service: .course,
      path: path,
      query: {
        'format': '-2',
        'code': context.credentials.username,
        'year': semester.year,
        'sem': semester.term,
      },
      extension: 'html',
      fileParts: _semesterFileParts(semester),
    );
  };
}

SnapshotRequestBuilder _requiredId({
  required SnapshotService service,
  required String path,
  required String option,
  required String filePrefix,
  required Map<String, dynamic> Function(String value) query,
}) {
  return (context, args) async {
    final value = _requiredOption(args, option);
    return SnapshotRequest(
      service: service,
      path: path,
      query: query(value),
      extension: 'html',
      fileParts: ['${_compactFilePrefix(filePrefix)}$value'],
    );
  };
}

SnapshotRequestBuilder _courseRequiredId({
  required String path,
  required String option,
  required String filePrefix,
  required Map<String, dynamic> Function(String value) query,
}) {
  return _requiredId(
    service: .course,
    path: path,
    option: option,
    filePrefix: filePrefix,
    query: query,
  );
}

SnapshotRequestBuilder _courseSemesterRequiredId({
  required String path,
  required String format,
  required String option,
  required String filePrefix,
}) {
  return (context, args) async {
    final semester = await _resolveCourseSemester(context, args);
    final value = _requiredOption(args, option);
    return SnapshotRequest(
      service: .course,
      path: path,
      query: {
        'format': format,
        'year': semester.year,
        'sem': semester.term,
        'code': value,
      },
      extension: 'html',
      fileParts: [
        ..._semesterFileParts(semester),
        '${_compactFilePrefix(filePrefix)}$value',
      ],
    );
  };
}

Future<SnapshotRequest> _offeringHeader(
  SnapshotContext context,
  ArgResults args,
) async {
  final courseNumber = _requiredOption(args, 'course-number');
  return SnapshotRequest(
    service: .course,
    path: 'tw/ShowSyllabus.jsp',
    query: {'snum': courseNumber},
    extension: 'html',
    fileParts: ['c$courseNumber', 'zh'],
  );
}

Future<SnapshotRequest> _offeringQuery(
  SnapshotContext context,
  ArgResults args,
) async {
  final courseNumber = _requiredOption(args, 'course-number');
  final headerResponse = await context
      .client(.course)
      .get(
        'tw/ShowSyllabus.jsp',
        queryParameters: {'snum': courseNumber},
      );
  final header = _parseOfferingSnapshotHeader(
    headerResponse.data,
    courseNumber: courseNumber,
  );

  return SnapshotRequest(
    service: .course,
    path: 'tw/QueryCourse.jsp',
    method: 'POST',
    data: {
      'year': header.year,
      'sem': header.term,
      // The legacy form encodes "all divisions" as one SQL-style value.
      'matric': "'0','1','4','5','6','7','8','9','A','C','D','E','F'",
      'unit': '＊',
      'cname': header.courseName,
      'ccode': '',
      'tname': '',
      'stime': '0',
    },
    contentType: Headers.formUrlEncodedContentType,
    extension: 'html',
    fileParts: [
      ..._semesterFileParts(
        SemesterRef(year: header.year, term: header.term),
      ),
      'c$courseNumber',
      'zh',
    ],
  );
}

({int year, int term, String courseName}) _parseOfferingSnapshotHeader(
  String html, {
  required String courseNumber,
}) {
  final document = parse(html);
  for (final table in document.querySelectorAll('table')) {
    final rows = table.querySelectorAll('tr');
    if (rows.length < 2) continue;
    final labels = rows.first.children.map((cell) => cell.text.trim()).toList();
    final numberIndex = labels.indexWhere(
      (label) => label == '課號' || label == 'Course Number',
    );
    final nameIndex = labels.indexWhere(
      (label) => label == '課程名稱' || label == 'Course Name',
    );
    if (numberIndex < 0 || nameIndex < 0) continue;
    final values = rows[1].children;
    if (numberIndex >= values.length ||
        nameIndex >= values.length ||
        values[numberIndex].text.trim() != courseNumber) {
      continue;
    }
    final courseName = values[nameIndex].text.trim();
    if (courseName.isEmpty) break;
    final semesterIndex = labels.indexOf('學年期');

    final semester = semesterIndex >= 0 && semesterIndex < values.length
        ? RegExp(
            r'^(\d+)\s*-\s*([0-3])$',
          ).firstMatch(values[semesterIndex].text.trim())
        : null;
    if (semester != null) {
      return (
        year: int.parse(semester.group(1)!),
        term: int.parse(semester.group(2)!),
        courseName: courseName,
      );
    }
    break;
  }
  throw CliException(
    'Could not resolve offering $courseNumber from the syllabus header.',
  );
}

Future<SnapshotRequest> _syllabus(
  SnapshotContext context,
  ArgResults args,
) async {
  final courseNumber = _requiredOption(args, 'course-number');
  final teacherId = _requiredOption(args, 'teacher-id');
  return SnapshotRequest(
    service: .course,
    path: 'tw/ShowSyllabus.jsp',
    query: {'snum': courseNumber, 'code': teacherId},
    extension: 'html',
    fileParts: ['c$courseNumber', 't$teacherId'],
  );
}

SnapshotRequestBuilder _ischoolCoursePage(
  String path, {
  String extension = 'html',
}) {
  return (context, args) async {
    final course = await _resolveISchoolCourse(context, args);
    return SnapshotRequest(
      service: .ischool,
      path: path,
      extension: extension,
      fileParts: [
        'c${course.courseNumber}',
        'i${course.internalId}',
      ],
      beforeRequests: [_selectISchoolCourseRequest(course)],
    );
  };
}

List<String> _semesterFileParts(SemesterRef semester) {
  return ['y${semester.year}', 't${semester.term}'];
}

String _compactFilePrefix(String prefix) {
  return switch (prefix) {
    'course' => 'c',
    'teacher' => 't',
    'classroom' => 'r',
    _ => prefix,
  };
}

Future<SemesterRef> _resolveCourseSemester(
  SnapshotContext context,
  ArgResults args,
) async {
  final yearArg = args['year'];
  final termArg = args['term'];
  if ((yearArg == null) != (termArg == null)) {
    throw CliException('Provide both --year and --term, or omit both.');
  }

  if (yearArg != null && termArg != null) {
    return SemesterRef(
      year: _parseIntOption('year', yearArg),
      term: _parseIntOption('term', termArg),
    );
  }

  final response = await context.client(.course).get('tw/Select.jsp');
  final semesters = _parseCourseSemesters(response.data);
  if (semesters.isEmpty) {
    throw CliException('No course semesters found for this account.');
  }
  return semesters.first;
}

List<SemesterRef> _parseCourseSemesters(String html) {
  final document = parse(html);
  final anchors = document.querySelectorAll('table a[href]');
  final semesters = <SemesterRef>[];

  for (final anchor in anchors) {
    final href = anchor.attributes['href'];
    if (href == null) continue;
    final query = Uri.parse(href).queryParameters;
    final year = int.tryParse(query['year'] ?? '');
    final term = int.tryParse(query['sem'] ?? '');
    if (year == null || term == null) continue;
    semesters.add(SemesterRef(year: year, term: term));
  }

  return semesters;
}

Future<ISchoolCourseRef> _resolveISchoolCourse(
  SnapshotContext context,
  ArgResults args,
) async {
  final internalId = args['course-internal-id'];
  final courseNumber = args['course-number'];
  if (internalId is String && internalId.isNotEmpty) {
    return ISchoolCourseRef(
      courseNumber: courseNumber is String && courseNumber.isNotEmpty
          ? courseNumber
          : 'unknown',
      internalId: internalId,
    );
  }

  final response = await context.client(.ischool).get('mooc_sysbar.php');
  final courses = _parseISchoolCourses(response.data);
  if (courses.isEmpty) {
    throw CliException('No iSchool+ courses found for this account.');
  }
  if (courseNumber is String && courseNumber.isNotEmpty) {
    for (final course in courses) {
      if (course.courseNumber == courseNumber) return course;
    }
    throw CliException(
      'No iSchool+ course matches --course-number $courseNumber.',
    );
  }
  return courses.first;
}

List<ISchoolCourseRef> _parseISchoolCourses(String html) {
  final document = parse(html);
  final options = document.querySelectorAll('#selcourse option');
  final courses = <ISchoolCourseRef>[];

  for (final option in options) {
    final internalId = option.attributes['value'];
    if (internalId == null || internalId.isEmpty) continue;

    final text = option.text;
    final underscore = text.lastIndexOf('_');
    if (underscore == -1) continue;
    final courseNumber = text.substring(underscore + 1).trim();
    if (courseNumber.isEmpty) continue;

    courses.add(
      ISchoolCourseRef(courseNumber: courseNumber, internalId: internalId),
    );
  }

  return courses;
}

SnapshotRequest _selectISchoolCourseRequest(ISchoolCourseRef course) {
  return SnapshotRequest(
    service: .ischool,
    path: 'goto_course.php',
    method: 'POST',
    data:
        '<manifest><ticket/><course_id>${course.internalId}</course_id><env/></manifest>',
    contentType: Headers.formUrlEncodedContentType,
  );
}
