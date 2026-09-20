import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/course_table/course_table_providers.dart';
import 'package:tattoo/screens/main/i_school_plus_providers.dart';
import 'package:tattoo/services/course/mock_course_service.dart';
import 'package:tattoo/services/firebase_service.dart';
import 'package:tattoo/services/i_school_plus/i_school_plus_service.dart';
import 'package:tattoo/services/i_school_plus/mock_i_school_plus_service.dart';
import 'package:tattoo/services/portal/mock_portal_service.dart';
import 'package:tattoo/services/student_query/mock_student_query_service.dart';

void main() {
  group('iSchoolPlusAvailabilityProvider', () {
    late _TestISchoolPlusService service;
    late ProviderContainer container;

    setUp(() {
      service = _TestISchoolPlusService();
      container = ProviderContainer(
        overrides: [iSchoolPlusServiceProvider.overrideWithValue(service)],
      );
    });

    tearDown(() => container.dispose());

    test('reports success from the service capability', () async {
      await container.read(iSchoolPlusAvailabilityProvider.future);

      expect(service.availabilityCalls, 1);
      expect(container.read(iSchoolPlusAvailabilityProvider).hasValue, isTrue);
    });

    test('reports failure without automatic retry', () async {
      service.availabilityError = Exception('unavailable');
      final subscription = container.listen(
        iSchoolPlusAvailabilityProvider,
        (_, _) {},
      );

      await expectLater(
        container.read(iSchoolPlusAvailabilityProvider.future),
        throwsA(isA<Exception>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(service.availabilityCalls, 1);
      expect(container.read(iSchoolPlusAvailabilityProvider).hasError, isTrue);
      subscription.close();
    });
  });

  group('course roster retry invariant', () {
    test('stays disabled while refresh is loading', () {
      expect(
        canRetryCourseStudentRoster(
          const AsyncLoading<bool>(),
          const AsyncError<void>('probe failed', StackTrace.empty),
        ),
        isFalse,
      );
    });

    test('stays disabled while probe is loading', () {
      expect(
        canRetryCourseStudentRoster(
          const AsyncError<bool>('refresh failed', StackTrace.empty),
          const AsyncLoading<void>(),
        ),
        isFalse,
      );
    });

    test('enables after refresh failure and probe settlement', () {
      expect(
        canRetryCourseStudentRoster(
          const AsyncError<bool>('refresh failed', StackTrace.empty),
          const AsyncData<void>(null),
        ),
        isTrue,
      );
      expect(
        canRetryCourseStudentRoster(
          const AsyncError<bool>('refresh failed', StackTrace.empty),
          const AsyncError<void>('probe failed', StackTrace.empty),
        ),
        isTrue,
      );
    });

    test('does not offer retry after a successful refresh', () {
      expect(
        canRetryCourseStudentRoster(
          const AsyncData<bool>(true),
          const AsyncError<void>('late probe failure', StackTrace.empty),
        ),
        isFalse,
      );
    });

    test('probe failure shows guide while refresh is still running', () {
      expect(
        courseRosterPresentation(
          hasCache: false,
          showNetworkGuide: false,
          allowEarlyNetworkGuide: true,
          refresh: const AsyncLoading<bool>(),
          availability: const AsyncError<void>(
            'probe failed',
            StackTrace.empty,
          ),
        ),
        CourseRosterPresentation.guide,
      );
    });

    test(
      'manual retry waits for authenticated refresh after probe failure',
      () {
        expect(
          courseRosterPresentation(
            hasCache: false,
            showNetworkGuide: false,
            allowEarlyNetworkGuide: false,
            refresh: const AsyncLoading<bool>(),
            availability: const AsyncError<void>(
              'probe failed',
              StackTrace.empty,
            ),
          ),
          CourseRosterPresentation.loading,
        );
      },
    );

    test('manual retry shows guide after both failures settle', () {
      expect(
        courseRosterPresentation(
          hasCache: false,
          showNetworkGuide: false,
          allowEarlyNetworkGuide: false,
          refresh: const AsyncError<bool>(
            'refresh failed',
            StackTrace.empty,
          ),
          availability: const AsyncError<void>(
            'probe failed',
            StackTrace.empty,
          ),
        ),
        CourseRosterPresentation.guide,
      );
    });

    test('refresh failure waits for the probe to settle', () {
      expect(
        courseRosterPresentation(
          hasCache: false,
          showNetworkGuide: false,
          allowEarlyNetworkGuide: true,
          refresh: const AsyncError<bool>(
            'refresh failed',
            StackTrace.empty,
          ),
          availability: const AsyncLoading<void>(),
        ),
        CourseRosterPresentation.loading,
      );
    });

    test('probe success plus refresh failure is a generic failure', () {
      expect(
        courseRosterPresentation(
          hasCache: false,
          showNetworkGuide: false,
          allowEarlyNetworkGuide: true,
          refresh: const AsyncError<bool>(
            'refresh failed',
            StackTrace.empty,
          ),
          availability: const AsyncData<void>(null),
        ),
        CourseRosterPresentation.genericFailure,
      );
    });

    test('a failed probe never replaces cached roster content', () {
      expect(
        courseRosterPresentation(
          hasCache: true,
          showNetworkGuide: false,
          allowEarlyNetworkGuide: true,
          refresh: const AsyncLoading<bool>(),
          availability: const AsyncError<void>(
            'probe failed',
            StackTrace.empty,
          ),
        ),
        CourseRosterPresentation.content,
      );
    });

    test('successful authenticated refresh wins over failed probe', () {
      expect(
        courseRosterPresentation(
          hasCache: true,
          showNetworkGuide: true,
          allowEarlyNetworkGuide: true,
          refresh: const AsyncData<bool>(true),
          availability: const AsyncError<void>(
            'probe failed',
            StackTrace.empty,
          ),
        ),
        CourseRosterPresentation.content,
      );
    });
  });

  group('course roster attempt providers', () {
    late AppDatabase database;
    late _TestISchoolPlusService service;
    late CourseRepository repository;
    late ProviderContainer container;
    late CourseRosterKey key;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      service = _TestISchoolPlusService();
      final portal = MockPortalService();
      final auth = AuthRepository(
        portalService: portal,
        studentQueryService: MockStudentQueryService(),
        database: database,
        secureStorage: const FlutterSecureStorage(),
        isDemo: false,
        onSessionCreated: () {},
        onSessionDestroyed: ([exception]) {},
      );
      repository = CourseRepository(
        portalService: portal,
        courseService: MockCourseService(),
        iSchoolPlusService: service,
        database: database,
        authRepository: auth,
        firebaseService: const FirebaseService(),
      );
      final semester = await database.getOrCreateSemester(114, 1);
      final offering = await database.upsertCourseOffering(
        semesterId: semester.id,
        number: '352902',
        nameZh: '測試課程',
      );
      key = (courseOfferingId: offering, courseNumber: '352902');
      container = ProviderContainer(
        overrides: [
          courseRepositoryProvider.overrideWithValue(repository),
          iSchoolPlusServiceProvider.overrideWithValue(service),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await database.close();
    });

    test('missing cache starts refresh and public probe', () async {
      final refresh = courseStudentRosterRefreshProvider(key);
      final availability = courseStudentRosterAvailabilityProvider(key);
      final refreshFuture = container.read(refresh.future);
      final availabilityFuture = container.read(availability.future);

      expect(await refreshFuture, isTrue);
      await availabilityFuture;

      expect(service.studentsCalls, 1);
      expect(service.availabilityCalls, 1);
    });

    test('fresh empty cache skips all network work', () async {
      service.courseListResult = [];
      await repository.refreshStudentRoster(
        courseOfferingId: key.courseOfferingId,
        courseNumber: key.courseNumber,
      );
      service.resetCalls();

      expect(
        await container.read(courseStudentRosterRefreshProvider(key).future),
        isFalse,
      );
      await container.read(
        courseStudentRosterAvailabilityProvider(key).future,
      );

      expect(service.courseListCalls, 0);
      expect(service.studentsCalls, 0);
      expect(service.availabilityCalls, 0);
    });

    test('stale cache starts background refresh and probe', () async {
      await repository.refreshStudentRoster(
        courseOfferingId: key.courseOfferingId,
        courseNumber: key.courseNumber,
      );
      await (database.update(database.courseOfferings)..where(
            (row) => row.id.equals(key.courseOfferingId),
          ))
          .write(
            CourseOfferingsCompanion(
              studentRosterFetchedAt: Value(
                DateTime.now().subtract(studentRosterTtl),
              ),
            ),
          );
      service.resetCalls();

      final refreshFuture = container.read(
        courseStudentRosterRefreshProvider(key).future,
      );
      final availabilityFuture = container.read(
        courseStudentRosterAvailabilityProvider(key).future,
      );
      expect(await refreshFuture, isTrue);
      await availabilityFuture;

      expect(service.studentsCalls, 1);
      expect(service.availabilityCalls, 1);
    });

    test('closing and reopening while loading reuses one refresh', () async {
      final students = Completer<List<StudentDto>>();
      service.studentsResultFuture = students.future;
      final provider = courseStudentRosterRefreshProvider(key);
      final firstSubscription = container.listen(provider, (_, _) {});
      final first = container.read(provider.future);
      await service.studentsStarted.future;

      firstSubscription.close();
      final secondSubscription = container.listen(provider, (_, _) {});
      final second = container.read(provider.future);
      await pumpEventQueue();
      expect(service.studentsCalls, 1);

      students.complete([(id: '111000001', name: '同學')]);
      await Future.wait([first, second]);
      expect(service.maxActiveStudents, 1);
      secondSubscription.close();
    });
  });
}

class _TestISchoolPlusService extends MockISchoolPlusService {
  Object? availabilityError;
  var availabilityCalls = 0;
  var courseListCalls = 0;
  var studentsCalls = 0;
  var activeStudents = 0;
  var maxActiveStudents = 0;
  Future<List<StudentDto>>? studentsResultFuture;
  Completer<void> studentsStarted = Completer<void>();

  void resetCalls() {
    availabilityCalls = 0;
    courseListCalls = 0;
    studentsCalls = 0;
  }

  @override
  Future<void> checkAvailability() async {
    availabilityCalls++;
    if (availabilityError case final error?) throw error;
  }

  @override
  Future<List<ISchoolCourseDto>> getCourseList() async {
    courseListCalls++;
    return super.getCourseList();
  }

  @override
  Future<List<StudentDto>> getStudents(ISchoolCourseDto course) async {
    studentsCalls++;
    activeStudents++;
    if (activeStudents > maxActiveStudents) maxActiveStudents = activeStudents;
    if (!studentsStarted.isCompleted) studentsStarted.complete();
    try {
      if (studentsResultFuture case final result?) return await result;
      return await super.getStudents(course);
    } finally {
      activeStudents--;
    }
  }
}
