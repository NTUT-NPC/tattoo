import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor, Value;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/course_repository.dart';
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
    late _RosterDeleteGate deleteGate;

    setUp(() async {
      deleteGate = _RosterDeleteGate();
      database = AppDatabase(NativeDatabase.memory().interceptWith(deleteGate));
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

    test('uses a 15-minute roster TTL', () async {
      iSchoolPlusService.studentsResult = [
        (id: '111000001', name: '同學'),
      ];
      await repository.refreshStudentRoster(
        courseOfferingId: courseOfferingId,
        courseNumber: '352902',
      );

      expect(
        await repository.isStudentRosterFresh(
          courseOfferingId: courseOfferingId,
        ),
        isTrue,
      );

      await (database.update(
        database.courseOfferings,
      )..where((row) => row.id.equals(courseOfferingId))).write(
        CourseOfferingsCompanion(
          studentRosterFetchedAt: Value(
            DateTime.now().subtract(const Duration(minutes: 15)),
          ),
        ),
      );
      expect(
        await repository.isStudentRosterFresh(
          courseOfferingId: courseOfferingId,
        ),
        isFalse,
      );
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
      'recovers cached students after a failed refresh',
      () async {
        iSchoolPlusService.studentsResult = [
          (id: '111000001', name: '第一次快取'),
        ];
        await repository.refreshStudentRoster(
          courseOfferingId: courseOfferingId,
          courseNumber: '352902',
        );
        final cached = await repository
            .watchStudentRoster(courseOfferingId)
            .first;

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
        final retained = await repository
            .watchStudentRoster(courseOfferingId)
            .first;
        expect(retained.fetchedAt, cached.fetchedAt);
        expect(retained.students.single.name, '第一次快取');

        iSchoolPlusService
          ..studentsError = null
          ..studentsResult = [
            (id: '111000002', name: '恢復後同學'),
          ];
        await repository.refreshStudentRoster(
          courseOfferingId: courseOfferingId,
          courseNumber: '352902',
        );
        final refreshed = await repository
            .watchStudentRoster(courseOfferingId)
            .first;
        expect(refreshed.fetchedAt, isNotNull);
        expect(
          refreshed.students.map((student) => student.name),
          ['恢復後同學'],
        );
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

    test('preserves a cached empty roster when refresh fails', () async {
      iSchoolPlusService.courseListResult = [];
      await repository.refreshStudentRoster(
        courseOfferingId: courseOfferingId,
        courseNumber: '352902',
      );
      final cachedAt =
          (await repository.watchStudentRoster(courseOfferingId).first)
              .fetchedAt;

      iSchoolPlusService
        ..courseListResult = null
        ..studentsError = DioException(
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

      expect(roster.students, isEmpty);
      expect(roster.fetchedAt, cachedAt);
    });

    test(
      'a newer refresh cancels the old request and is the only DB writer',
      () async {
        final firstStudents = Completer<List<StudentDto>>();
        iSchoolPlusService.studentsCompleter = firstStudents;

        final firstRefresh = repository.refreshStudentRoster(
          courseOfferingId: courseOfferingId,
          courseNumber: '352902',
        );
        final firstResult = expectLater(
          firstRefresh,
          throwsA(
            isA<DioException>().having(
              (error) => error.type == .cancel,
              'is cancelled',
              isTrue,
            ),
          ),
        );
        await iSchoolPlusService.studentsRequested.future;

        iSchoolPlusService
          ..studentsCompleter = null
          ..studentsResult = [(id: '111000002', name: '最新同學')];
        await repository.refreshStudentRoster(
          courseOfferingId: courseOfferingId,
          courseNumber: '352902',
        );
        await firstResult;
        firstStudents.complete([(id: '111000001', name: '過期同學')]);

        final roster = await repository
            .watchStudentRoster(courseOfferingId)
            .first;
        expect(iSchoolPlusService.cancelTokens.first.isCancelled, isTrue);
        expect(
          roster.students.map((student) => student.name),
          ['最新同學'],
        );
      },
    );

    test(
      'cancellation after network completion prevents a stale DB write',
      () async {
        final firstStudents = Completer<List<StudentDto>>();
        iSchoolPlusService.studentsCompleter = firstStudents;
        final firstResult = expectLater(
          repository.refreshStudentRoster(
            courseOfferingId: courseOfferingId,
            courseNumber: '352902',
          ),
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.cancel,
            ),
          ),
        );
        await iSchoolPlusService.studentsRequested.future;

        firstStudents.complete([(id: '111000001', name: '舊同學')]);
        iSchoolPlusService
          ..studentsCompleter = null
          ..studentsResult = [(id: '111000002', name: '新同學')];
        await repository.refreshStudentRoster(
          courseOfferingId: courseOfferingId,
          courseNumber: '352902',
        );
        await firstResult;

        final roster = await repository
            .watchStudentRoster(courseOfferingId)
            .first;
        expect(roster.students.map((student) => student.name), ['新同學']);
        expect(deleteGate.rosterDeletes, 1);
      },
    );

    test(
      'refreshes for different offerings do not cancel each other',
      () async {
        final semester = await database.getOrCreateSemester(114, 1);
        final secondOfferingId = await database.upsertCourseOffering(
          semesterId: semester.id,
          number: '352903',
          nameZh: '另一門課',
        );
        iSchoolPlusService.courseListResult = [
          (courseNumber: '352902', internalId: '101'),
          (courseNumber: '352903', internalId: '202'),
        ];
        final firstStudents = Completer<List<StudentDto>>();
        iSchoolPlusService.studentsCompleter = firstStudents;
        final firstRefresh = repository.refreshStudentRoster(
          courseOfferingId: courseOfferingId,
          courseNumber: '352902',
        );
        await iSchoolPlusService.studentsRequested.future;

        iSchoolPlusService
          ..studentsCompleter = null
          ..studentsResult = [(id: '111000002', name: '第二門課同學')];
        await repository.refreshStudentRoster(
          courseOfferingId: secondOfferingId,
          courseNumber: '352903',
        );
        firstStudents.complete([(id: '111000001', name: '第一門課同學')]);
        await firstRefresh;

        expect(iSchoolPlusService.cancelTokens.first.isCancelled, isFalse);
        expect(
          (await repository.watchStudentRoster(courseOfferingId).first)
              .students
              .single
              .name,
          '第一門課同學',
        );
        expect(
          (await repository.watchStudentRoster(secondOfferingId).first)
              .students
              .single
              .name,
          '第二門課同學',
        );
      },
    );

    test(
      'cancellation during a transaction rolls back partial roster writes',
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

        deleteGate.pauseNextDelete = true;
        iSchoolPlusService.studentsResult = [
          (id: '111000002', name: '不應留下'),
        ];
        final firstResult = expectLater(
          repository.refreshStudentRoster(
            courseOfferingId: courseOfferingId,
            courseNumber: '352902',
          ),
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.cancel,
            ),
          ),
        );
        await deleteGate.deleted.future;

        iSchoolPlusService.studentsError = DioException(
          requestOptions: RequestOptions(path: '/learn/learn_ranking.php'),
          type: .connectionError,
        );
        final secondResult = expectLater(
          repository.refreshStudentRoster(
            courseOfferingId: courseOfferingId,
            courseNumber: '352902',
          ),
          throwsA(isA<DioException>()),
        );
        deleteGate.resume.complete();
        await firstResult;
        await secondResult;

        final roster = await repository
            .watchStudentRoster(courseOfferingId)
            .first;
        expect(roster.fetchedAt, cachedAt);
        expect(roster.students.map((student) => student.name), ['快取同學']);
      },
    );
  });
}

class _RosterDeleteGate extends QueryInterceptor {
  bool pauseNextDelete = false;
  int rosterDeletes = 0;
  final deleted = Completer<void>();
  final resume = Completer<void>();

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final result = await executor.runDelete(statement, args);
    if (statement.toLowerCase().contains('course_offering_students')) {
      rosterDeletes++;
      if (pauseNextDelete) {
        pauseNextDelete = false;
        deleted.complete();
        await resume.future;
      }
    }
    return result;
  }
}

class _TestISchoolPlusService extends MockISchoolPlusService {
  Object? studentsError;
  int studentsCalls = 0;
  Completer<List<StudentDto>>? studentsCompleter;
  Completer<void> studentsRequested = Completer<void>();
  final List<CancelToken> cancelTokens = [];

  @override
  Future<List<StudentDto>> getStudents(
    ISchoolCourseDto course, {
    CancelToken? cancelToken,
  }) async {
    studentsCalls++;
    if (!studentsRequested.isCompleted) studentsRequested.complete();
    if (cancelToken case final token?) cancelTokens.add(token);
    if (studentsError case final error?) throw error;
    if (studentsCompleter case final completer?) {
      return Future.any([
        completer.future,
        if (cancelToken case final token?)
          token.whenCancel.then((error) => throw error),
      ]);
    }
    return super.getStudents(course, cancelToken: cancelToken);
  }
}
