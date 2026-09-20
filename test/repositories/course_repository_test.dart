import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/services/course/course_service.dart';
import 'package:tattoo/services/course/mock_course_service.dart';
import 'package:tattoo/services/firebase_service.dart';
import 'package:tattoo/services/i_school_plus/i_school_plus_service.dart';
import 'package:tattoo/services/i_school_plus/mock_i_school_plus_service.dart';
import 'package:tattoo/services/portal/mock_portal_service.dart';
import 'package:tattoo/services/student_query/mock_student_query_service.dart';

void main() {
  group('CourseRepository student roster', () {
    late AppDatabase database;
    late _TestISchoolPlusService iSchoolPlusService;
    late CourseRepository repository;
    late int courseOfferingId;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      iSchoolPlusService = _TestISchoolPlusService();
      final portalService = MockPortalService();
      final authRepository = AuthRepository(
        portalService: portalService,
        studentQueryService: MockStudentQueryService(),
        database: database,
        secureStorage: const FlutterSecureStorage(),
        isDemo: false,
        onSessionCreated: () {},
        onSessionDestroyed: ([exception]) {},
      );
      repository = CourseRepository(
        portalService: portalService,
        courseService: MockCourseService(),
        iSchoolPlusService: iSchoolPlusService,
        database: database,
        authRepository: authRepository,
        firebaseService: const FirebaseService(),
      );

      final semester = await database.getOrCreateSemester(114, 1);
      courseOfferingId = await database.upsertCourseOffering(
        semesterId: semester.id,
        number: '352902',
        nameZh: '測試課程',
      );
    });

    tearDown(() => database.close());

    test('refreshes and watches a normalized roster', () async {
      iSchoolPlusService.studentsResult = [
        (id: ' 112000002 ', name: '  王小明  '),
        (id: '111000001', name: null),
        (id: null, name: '沒有學號'),
        (id: '111000001', name: '重複資料'),
      ];

      await repository.refreshStudentRoster(
        courseOfferingId: courseOfferingId,
        courseNumber: '352902',
      );
      final roster = await repository
          .watchStudentRoster(courseOfferingId)
          .first;

      expect(roster.fetchedAt, isNotNull);
      expect(
        roster.students.map((student) => (student.studentId, student.name)),
        [('111000001', null), ('112000002', '王小明')],
      );
      expect(iSchoolPlusService.studentsCalls, 1);
    });

    test('replaces stale relationships after a successful refresh', () async {
      iSchoolPlusService.studentsResult = [
        (id: '111000001', name: '舊同學'),
        (id: '111000002', name: '將被移除'),
      ];
      await repository.refreshStudentRoster(
        courseOfferingId: courseOfferingId,
        courseNumber: '352902',
      );

      iSchoolPlusService.studentsResult = [
        (id: '111000001', name: '新名字'),
        (id: '111000003', name: '新同學'),
      ];
      await repository.refreshStudentRoster(
        courseOfferingId: courseOfferingId,
        courseNumber: '352902',
      );
      final roster = await repository
          .watchStudentRoster(courseOfferingId)
          .first;

      expect(
        roster.students.map((student) => (student.studentId, student.name)),
        [('111000001', '新名字'), ('111000003', '新同學')],
      );
    });

    test(
      'preserves cached students when refresh has a network error',
      () async {
        iSchoolPlusService.studentsResult = [
          (id: '111000001', name: '快取同學'),
        ];
        await repository.refreshStudentRoster(
          courseOfferingId: courseOfferingId,
          courseNumber: '352902',
        );
        final cachedAt =
            (await repository.watchStudentRoster(courseOfferingId).first)
                .fetchedAt;

        iSchoolPlusService.studentsError = DioException(
          requestOptions: RequestOptions(path: '/learn/learn_ranking.php'),
          type: .connectionError,
        );

        await expectLater(
          repository.refreshStudentRoster(
            courseOfferingId: courseOfferingId,
            courseNumber: '352902',
          ),
          throwsA(isA<DioException>()),
        );
        final roster = await repository
            .watchStudentRoster(courseOfferingId)
            .first;

        expect(roster.fetchedAt, cachedAt);
        expect(roster.students.single.name, '快取同學');
      },
    );

    test(
      'caches an empty roster when the course is absent from iSchool',
      () async {
        iSchoolPlusService.courseListResult = [];

        await repository.refreshStudentRoster(
          courseOfferingId: courseOfferingId,
          courseNumber: '352902',
        );
        final roster = await repository
            .watchStudentRoster(courseOfferingId)
            .first;

        expect(roster.students, isEmpty);
        expect(roster.fetchedAt, isNotNull);
        expect(iSchoolPlusService.studentsCalls, 0);
      },
    );
  });

  group('CourseRepository widget cache', () {
    late AppDatabase database;
    late _CountingCourseService courseService;
    late CourseRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      courseService = _CountingCourseService();
      final portalService = MockPortalService();
      repository = CourseRepository(
        portalService: portalService,
        courseService: courseService,
        iSchoolPlusService: MockISchoolPlusService(),
        database: database,
        authRepository: AuthRepository(
          portalService: portalService,
          studentQueryService: MockStudentQueryService(),
          database: database,
          secureStorage: const FlutterSecureStorage(),
          isDemo: false,
          onSessionCreated: () {},
          onSessionDestroyed: ([exception]) {},
        ),
        firebaseService: const FirebaseService(),
      );
    });

    tearDown(() => database.close());

    test(
      'reads and normalizes only the latest eligible cached semester',
      () async {
        final older = await database.getOrCreateSemester(
          113,
          2,
          inCourseSemesterList: true,
        );
        await database.getOrCreateSemester(
          115,
          1,
          inCourseSemesterList: false,
        );
        final latest = await database.getOrCreateSemester(
          114,
          1,
          inCourseSemesterList: true,
        );
        final olderOffering = await database.upsertCourseOffering(
          semesterId: older.id,
          number: 'older',
          nameZh: '舊課程',
          inCourseTable: true,
        );
        await database
            .into(database.schedules)
            .insert(
              SchedulesCompanion.insert(
                courseOffering: olderOffering,
                dayOfWeek: DayOfWeek.monday,
                period: Period.first,
              ),
            );

        await database.upsertCourse(
          code: 'CS100',
          credits: 3,
          hours: 2,
          nameZh: '快取課程',
          nameEn: 'Cached Course',
        );
        final classroom = await database.upsertClassroom(
          code: 'ROOM',
          nameZh: '共同101',
          nameEn: 'GSB 101',
        );
        final scheduled = await database.upsertCourseOffering(
          semesterId: latest.id,
          number: 'latest',
          nameZh: '快取課程',
          nameEn: 'Cached Course',
          courseCode: const Value('CS100'),
          inCourseTable: true,
        );
        final unscheduled = await database.upsertCourseOffering(
          semesterId: latest.id,
          number: 'unscheduled',
          nameZh: '專題',
          nameEn: 'Project',
          inCourseTable: true,
        );
        for (final period in [Period.fourth, Period.fifth]) {
          await database
              .into(database.schedules)
              .insert(
                SchedulesCompanion.insert(
                  courseOffering: scheduled,
                  dayOfWeek: DayOfWeek.tuesday,
                  period: period,
                  classroom: Value(classroom),
                ),
              );
        }

        final result = await repository.readLatestCachedCourseTable();

        expect((result!.semester.year, result.semester.term), (114, 1));
        final cell = result.courseTable.scheduled.values.single;
        expect((cell.id, cell.span, cell.crossesNoon), (scheduled, 2, true));
        expect(result.courseTable.unscheduled.single.id, unscheduled);
        expect(courseService.semesterListCalls, 0);
        expect(courseService.courseTableCalls, 0);
      },
    );

    test('signals cache changes after a transaction completes', () async {
      final stream = repository.watchCourseTableCacheChanges();
      final changed = stream.skip(1).first.timeout(const Duration(seconds: 2));
      await Future<void>.delayed(Duration.zero);

      await database.transaction(() async {
        await database.getOrCreateSemester(
          114,
          2,
          inCourseSemesterList: true,
        );
        await database.upsertClassroom(
          code: 'SECOND',
          nameZh: '第二教學大樓',
        );
      });

      await changed;
    });
  });
}

class _CountingCourseService extends MockCourseService {
  var semesterListCalls = 0;
  var courseTableCalls = 0;

  @override
  Future<List<SemesterDto>> getCourseSemesterList() {
    semesterListCalls++;
    return super.getCourseSemesterList();
  }

  @override
  Future<List<ScheduleDto>> getCourseTable({
    required String username,
    required SemesterDto semester,
  }) {
    courseTableCalls++;
    return super.getCourseTable(username: username, semester: semester);
  }
}

class _TestISchoolPlusService extends MockISchoolPlusService {
  Object? studentsError;
  int studentsCalls = 0;

  @override
  Future<List<StudentDto>> getStudents(ISchoolCourseDto course) async {
    studentsCalls++;
    if (studentsError case final error?) throw error;
    return super.getStudents(course);
  }
}
