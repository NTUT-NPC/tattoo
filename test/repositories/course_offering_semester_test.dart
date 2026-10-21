import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/repositories/student_repository.dart';
import 'package:tattoo/services/course/course_service.dart';
import 'package:tattoo/services/course/mock_course_service.dart';
import 'package:tattoo/services/firebase_service.dart';
import 'package:tattoo/services/i_school_plus/mock_i_school_plus_service.dart';
import 'package:tattoo/services/portal/mock_portal_service.dart';
import 'package:tattoo/services/student_query/mock_student_query_service.dart';

void main() {
  group('Summer timetable and following-semester scores', () {
    late AppDatabase database;
    late CourseRepository courses;
    late StudentRepository student;
    late Semester summer;
    late Semester fall;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      final portalService = MockPortalService();
      final studentService = MockStudentQueryService()
        ..gpaResult = []
        ..gradeRankingResult = []
        ..academicPerformanceResult = [
          (
            semester: (year: 115, term: 1),
            scores: [
              (
                number: '367111',
                courseNameZh: '校外實習',
                courseNameEn: 'Internship',
                courseCode: 'INTERNSHIP',
                score: 80,
                status: null,
              ),
            ],
            average: 80,
            conduct: null,
            totalCredits: 2,
            creditsPassed: 2,
            note: null,
          ),
        ];
      final courseService = _SummerCourseService()
        ..courseResult = (
          id: 'INTERNSHIP',
          nameZh: '校外實習',
          nameEn: 'Internship',
          credits: 2,
          hours: 0,
          descriptionZh: null,
          descriptionEn: null,
        );
      final auth = AuthRepository(
        portalService: portalService,
        studentQueryService: studentService,
        database: database,
        secureStorage: const FlutterSecureStorage(),
        isDemo: false,
        clearCourseWidget: () async {},
        onSessionCreated: () {},
        onSessionDestroyed: ([exception]) {},
      );
      courses = CourseRepository(
        portalService: portalService,
        courseService: courseService,
        iSchoolPlusService: MockISchoolPlusService(),
        database: database,
        authRepository: auth,
        firebaseService: const FirebaseService(),
      );
      student = StudentRepository(
        database: database,
        authRepository: auth,
        courseRepository: courses,
        firebaseService: const FirebaseService(),
        studentQueryService: studentService,
      );
      await database
          .into(database.users)
          .insert(
            UsersCompanion.insert(
              studentId: '111000001',
              nameZh: 'Test Student',
              avatarFilename: '',
              email: 'student@example.com',
            ),
          );
      summer = await database.getOrCreateSemester(115, 0);
      fall = await database.getOrCreateSemester(115, 1);
    });

    tearDown(() => database.close());

    Future<void> expectSeparateSemesters(int offeringId) async {
      final offering = await database
          .select(database.courseOfferings)
          .getSingle();
      expect(offering.id, offeringId);
      expect(offering.semester, summer.id);
      expect(offering.inCourseTable, isTrue);
      final score = await database.select(database.scores).getSingle();
      expect(score.courseOffering, offeringId);
      expect(score.semester, fall.id);
      expect(score.score, 80);

      final summerTable = await courses
          .watchCourseTable(semesterId: summer.id)
          .first;
      expect(summerTable.unscheduled.map((course) => course.number), [
        '367111',
      ]);
      final fallTable = await courses
          .watchCourseTable(semesterId: fall.id)
          .first;
      expect(fallTable.scheduled, isEmpty);
      expect(fallTable.unscheduled, isEmpty);
      expect(
        await database.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    }

    for (final alreadyInTimetable in [false, true]) {
      test(
        alreadyInTimetable
            ? 'repairs an internship already shown in the wrong timetable'
            : 'corrects a score-created internship when loading its timetable',
        () async {
          await student.refreshSemesterRecords();
          final cached = await database
              .select(database.courseOfferings)
              .getSingle();
          final score = await database.select(database.scores).getSingle();
          expect(cached.semester, fall.id);
          expect(cached.inCourseTable, isFalse);
          if (alreadyInTimetable) {
            await database
                .update(database.courseOfferings)
                .write(
                  const CourseOfferingsCompanion(inCourseTable: Value(true)),
                );
          }

          await courses.refreshCourseTable(semesterId: summer.id);

          await expectSeparateSemesters(cached.id);
          expect(
            (await database.select(database.scores).getSingle()).id,
            score.id,
          );
        },
      );
    }

    test(
      'loading scores later preserves the summer timetable semester',
      () async {
        await courses.refreshCourseTable(semesterId: summer.id);
        final cached = await database
            .select(database.courseOfferings)
            .getSingle();

        await student.refreshSemesterRecords();

        await expectSeparateSemesters(cached.id);
      },
    );
  });
}

class _SummerCourseService extends MockCourseService {
  @override
  Future<List<ScheduleDto>> getCourseTable({
    required String username,
    required SemesterDto semester,
  }) async {
    return switch (semester) {
      (year: 115, term: 0) => [
        (
          number: '367111',
          course: (id: 'INTERNSHIP', nameZh: '校外實習', nameEn: 'Internship'),
          phase: null,
          credits: 2,
          hours: 0,
          type: null,
          teachers: null,
          classes: null,
          schedule: [],
          status: null,
          language: null,
          remarks: null,
        ),
      ],
      _ => [],
    };
  }
}
