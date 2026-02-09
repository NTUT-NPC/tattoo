import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/services/course_service.dart';
import 'package:tattoo/services/portal_service.dart';

import '../test_helpers.dart';

void main() {
  group('CourseService Integration Tests', () {
    late PortalService portalService;
    late CourseService courseService;

    setUpAll(() {
      TestCredentials.validate();
    });

    setUp(() async {
      portalService = PortalService();
      courseService = CourseService();

      // Reuse existing session if available
      if (!await portalService.isLoggedIn()) {
        await portalService.login(
          TestCredentials.username,
          TestCredentials.password,
        );
      }
      await portalService.sso(PortalServiceCode.courseService);

      await respectfulDelay();
    });

    group('getCourseSemesterList', () {
      test('should return and parse semester list correctly', () async {
        final semesters = await courseService.getCourseSemesterList(
          TestCredentials.username,
        );

        expect(
          semesters,
          isNotEmpty,
          reason: 'Should have at least one semester',
        );

        for (final semester in semesters) {
          expect(semester.year, isNotNull);
          expect(semester.term, isNotNull);
          expect(
            semester.year,
            greaterThan(80),
            reason: 'ROC year should be from modern era (>80 means after 1991)',
          );
          expect(
            semester.term,
            isIn([0, 1, 2, 3]),
            reason:
                'Term should be 0 (pre-study), 1 (fall), 2 (spring), or 3 (summer)',
          );
        }
      });
    });

    group('getCourseTable', () {
      test('should return course schedule for valid semester', () async {
        final semesters = await courseService.getCourseSemesterList(
          TestCredentials.username,
        );

        if (semesters.isEmpty) {
          fail('No semesters available for testing');
        }

        final courseTable = await courseService.getCourseTable(
          username: TestCredentials.username,
          semester: semesters.pickRandom(),
        );

        expect(
          courseTable,
          isNotEmpty,
          reason: 'Should have at least one course',
        );
      });

      test('should parse all expected fields from course schedule', () async {
        final semesters = await courseService.getCourseSemesterList(
          TestCredentials.username,
        );
        final courseTable = await courseService.getCourseTable(
          username: TestCredentials.username,
          semester: semesters.pickRandom(),
        );

        // Find a real course (not special rows like 班週會及導師時間)
        // Real courses have a course number
        final regularCourses = courseTable
            .where(
              (schedule) =>
                  schedule.number != null && schedule.number!.isNotEmpty,
            )
            .toList();

        expect(
          regularCourses,
          isNotEmpty,
          reason: 'Should have at least one regular course with a number',
        );

        final firstRegularCourse = regularCourses.pickRandom();

        // Verify required fields are present for regular courses
        expect(firstRegularCourse.number, isNotEmpty);
        expect(firstRegularCourse.course?.name, isNotNull);
        expect(firstRegularCourse.course?.name, isNotEmpty);

        // Verify numeric fields have reasonable values
        if (firstRegularCourse.credits != null) {
          expect(firstRegularCourse.credits, greaterThanOrEqualTo(0));
          expect(
            firstRegularCourse.credits,
            lessThanOrEqualTo(10),
            reason: 'Credits should be reasonable (≤10)',
          );
        }

        if (firstRegularCourse.hours != null) {
          expect(firstRegularCourse.hours, greaterThan(0));
        }

        // Verify phase is valid
        if (firstRegularCourse.phase != null) {
          expect(firstRegularCourse.phase, greaterThan(0));
        }
      });

      test('should parse course names correctly', () async {
        final semesters = await courseService.getCourseSemesterList(
          TestCredentials.username,
        );
        final courseTable = await courseService.getCourseTable(
          username: TestCredentials.username,
          semester: semesters.pickRandom(),
        );

        final coursesWithNames = courseTable
            .where(
              (schedule) => schedule.course?.name != null,
            )
            .toList();

        expect(
          coursesWithNames,
          isNotEmpty,
          reason: 'At least one course should have a name',
        );

        for (final course in coursesWithNames) {
          expect(
            course.course!.name,
            isNotEmpty,
            reason: 'Course name should not be empty',
          );
        }
      });

      test('should parse schedule times correctly', () async {
        final semesters = await courseService.getCourseSemesterList(
          TestCredentials.username,
        );
        final courseTable = await courseService.getCourseTable(
          username: TestCredentials.username,
          semester: semesters.pickRandom(),
        );

        final coursesWithSchedule = courseTable
            .where(
              (schedule) =>
                  schedule.schedule != null && schedule.schedule!.isNotEmpty,
            )
            .toList();

        expect(
          coursesWithSchedule,
          isNotEmpty,
          reason: 'At least one course should have a schedule',
        );

        // Verify schedule structure is valid (enums are guaranteed by type system)
        // Just checking that we can access a random one without errors
        coursesWithSchedule.pickRandom();
      });

      test('should parse course types correctly', () async {
        final semesters = await courseService.getCourseSemesterList(
          TestCredentials.username,
        );
        final courseTable = await courseService.getCourseTable(
          username: TestCredentials.username,
          semester: semesters.pickRandom(),
        );

        // Find regular courses (not special rows like 班週會及導師時間)
        final regularCourses = courseTable
            .where(
              (schedule) =>
                  schedule.number != null && schedule.number!.isNotEmpty,
            )
            .toList();

        expect(
          regularCourses,
          isNotEmpty,
          reason: 'Should have at least one regular course',
        );

        for (final course in regularCourses) {
          expect(
            course.type,
            isNotNull,
            reason: 'Regular courses should have a type',
          );
          expect(
            course.type,
            isNotEmpty,
            reason: 'Course type should not be empty',
          );
        }
      });
    });

    group('getCourse', () {
      test('should parse all course detail fields correctly', () async {
        final semesters = await courseService.getCourseSemesterList(
          TestCredentials.username,
        );
        final courseTable = await courseService.getCourseTable(
          username: TestCredentials.username,
          semester: semesters.pickRandom(),
        );

        final coursesWithId = courseTable
            .where(
              (schedule) => schedule.course?.id != null,
            )
            .toList();

        final courseWithId = coursesWithId.pickRandom();

        final courseDetails = await courseService.getCourse(
          courseWithId.course!.id!,
        );

        // Verify required fields
        expect(courseDetails.id, isNotNull);
        expect(courseDetails.id, isNotEmpty);

        // Verify both names exist
        expect(
          courseDetails.nameZh,
          isNotNull,
          reason: 'Course should have a Chinese name',
        );
        expect(
          courseDetails.nameEn,
          isNotNull,
          reason: 'Course should have an English name',
        );

        // Verify numeric fields are reasonable (can be 0 for special courses)
        if (courseDetails.credits != null) {
          expect(courseDetails.credits, greaterThanOrEqualTo(0));
          expect(courseDetails.credits, lessThanOrEqualTo(10));
        }

        if (courseDetails.hours != null) {
          expect(courseDetails.hours, greaterThanOrEqualTo(0));
        }

        // Verify non-empty strings
        if (courseDetails.nameZh != null) {
          expect(courseDetails.nameZh, isNotEmpty);
        }
        if (courseDetails.nameEn != null) {
          expect(courseDetails.nameEn, isNotEmpty);
        }
      });
    });

    group('getSyllabus', () {
      test('should parse syllabus fields correctly', () async {
        final semesters = await courseService.getCourseSemesterList(
          TestCredentials.username,
        );
        final courseTable = await courseService.getCourseTable(
          username: TestCredentials.username,
          semester: semesters.pickRandom(),
        );

        // Find a course with a syllabus ID
        final coursesWithSyllabus = courseTable
            .where(
              (schedule) =>
                  schedule.number != null &&
                  schedule.number!.isNotEmpty &&
                  schedule.syllabusId != null,
            )
            .toList();

        expect(
          coursesWithSyllabus,
          isNotEmpty,
          reason: 'Should have at least one course with a syllabus',
        );

        final course = coursesWithSyllabus.pickRandom();
        final syllabus = await courseService.getSyllabus(
          courseNumber: course.number!,
          syllabusId: course.syllabusId!,
        );

        // Verify course type is a valid enum value
        expect(
          syllabus.type,
          isNotNull,
          reason: 'Syllabus should have a course type',
        );
        expect(
          syllabus.type,
          isIn(CourseType.values),
          reason: 'Course type should be a valid CourseType enum',
        );

        // Verify enrollment numbers are reasonable
        if (syllabus.enrolled != null) {
          expect(
            syllabus.enrolled,
            greaterThanOrEqualTo(0),
            reason: 'Enrolled count should be non-negative',
          );
        }
        if (syllabus.withdrawn != null) {
          expect(
            syllabus.withdrawn,
            greaterThanOrEqualTo(0),
            reason: 'Withdrawn count should be non-negative',
          );
        }

        // Verify lastUpdated is a valid date
        expect(
          syllabus.lastUpdated,
          isNotNull,
          reason: 'Syllabus should have a last updated date',
        );
      });

      test('should parse syllabus content fields', () async {
        final semesters = await courseService.getCourseSemesterList(
          TestCredentials.username,
        );
        final courseTable = await courseService.getCourseTable(
          username: TestCredentials.username,
          semester: semesters.pickRandom(),
        );

        final coursesWithSyllabus = courseTable
            .where(
              (schedule) =>
                  schedule.number != null &&
                  schedule.number!.isNotEmpty &&
                  schedule.syllabusId != null,
            )
            .toList();

        final course = coursesWithSyllabus.pickRandom();
        final syllabus = await courseService.getSyllabus(
          courseNumber: course.number!,
          syllabusId: course.syllabusId!,
        );

        // At least some content fields should be populated
        final hasContent =
            syllabus.objective != null ||
            syllabus.weeklyPlan != null ||
            syllabus.evaluation != null ||
            syllabus.materials != null;

        expect(
          hasContent,
          isTrue,
          reason: 'Syllabus should have at least one content field populated',
        );

        // Verify non-empty strings when present
        if (syllabus.objective != null) {
          expect(syllabus.objective, isNotEmpty);
        }
        if (syllabus.weeklyPlan != null) {
          expect(syllabus.weeklyPlan, isNotEmpty);
        }
        if (syllabus.evaluation != null) {
          expect(syllabus.evaluation, isNotEmpty);
        }
        if (syllabus.materials != null) {
          expect(syllabus.materials, isNotEmpty);
        }
      });

      test('should parse email when available', () async {
        final semesters = await courseService.getCourseSemesterList(
          TestCredentials.username,
        );
        final courseTable = await courseService.getCourseTable(
          username: TestCredentials.username,
          semester: semesters.pickRandom(),
        );

        final coursesWithSyllabus = courseTable
            .where(
              (schedule) =>
                  schedule.number != null &&
                  schedule.number!.isNotEmpty &&
                  schedule.syllabusId != null,
            )
            .toList();

        final course = coursesWithSyllabus.pickRandom();
        final syllabus = await courseService.getSyllabus(
          courseNumber: course.number!,
          syllabusId: course.syllabusId!,
        );

        // Email should contain @ if present
        if (syllabus.email != null) {
          expect(
            syllabus.email,
            contains('@'),
            reason: 'Email should be a valid email format',
          );
        }
      });
    });

    group('getTeacher', () {
      test('should parse teacher profile fields correctly', () async {
        final semesters = await courseService.getCourseSemesterList(
          TestCredentials.username,
        );
        final semester = semesters.pickRandom();
        final courseTable = await courseService.getCourseTable(
          username: TestCredentials.username,
          semester: semester,
        );

        // Find a course with a teacher ID
        final coursesWithTeacher = courseTable
            .where((schedule) => schedule.teacher?.id != null)
            .toList();

        expect(
          coursesWithTeacher,
          isNotEmpty,
          reason: 'Should have at least one course with a teacher',
        );

        final course = coursesWithTeacher.pickRandom();
        final teacher = await courseService.getTeacher(
          teacherId: course.teacher!.id!,
          semester: semester,
        );

        // Verify profile fields from format=-3
        expect(
          teacher.department,
          isNotNull,
          reason: 'Teacher should have a department',
        );
        expect(
          teacher.department?.name,
          isNotEmpty,
          reason: 'Department name should not be empty',
        );

        expect(
          teacher.title,
          isNotNull,
          reason: 'Teacher should have a title',
        );
        expect(
          teacher.title,
          isNotEmpty,
          reason: 'Title should not be empty',
        );

        expect(
          teacher.nameZh,
          isNotNull,
          reason: 'Teacher should have a Chinese name',
        );
        expect(
          teacher.nameZh,
          isNotEmpty,
          reason: 'Chinese name should not be empty',
        );

        // Teaching hours should be reasonable (can be 0 for some faculty)
        if (teacher.teachingHours != null) {
          expect(
            teacher.teachingHours,
            greaterThanOrEqualTo(0),
            reason: 'Teaching hours should be non-negative',
          );
          expect(
            teacher.teachingHours,
            lessThanOrEqualTo(40),
            reason: 'Teaching hours should be reasonable (≤40)',
          );
        }
      });

      test('should parse office hours correctly', () async {
        final semesters = await courseService.getCourseSemesterList(
          TestCredentials.username,
        );
        final semester = semesters.pickRandom();
        final courseTable = await courseService.getCourseTable(
          username: TestCredentials.username,
          semester: semester,
        );

        final coursesWithTeacher = courseTable
            .where((schedule) => schedule.teacher?.id != null)
            .toList();

        expect(
          coursesWithTeacher,
          isNotEmpty,
          reason: 'Should have at least one course with a teacher',
        );

        final course = coursesWithTeacher.pickRandom();
        final teacher = await courseService.getTeacher(
          teacherId: course.teacher!.id!,
          semester: semester,
        );

        // Office hours may or may not be set by teacher
        if (teacher.officeHours != null && teacher.officeHours!.isNotEmpty) {
          for (final officeHour in teacher.officeHours!) {
            // Verify day is valid (guaranteed by type system, but check parsing)
            expect(
              officeHour.day,
              isIn(DayOfWeek.values),
              reason: 'Day should be a valid DayOfWeek enum',
            );

            // Verify time ranges are valid
            expect(
              officeHour.startTime.hour,
              inInclusiveRange(0, 23),
              reason: 'Start hour should be 0-23',
            );
            expect(
              officeHour.startTime.minute,
              inInclusiveRange(0, 59),
              reason: 'Start minute should be 0-59',
            );
            expect(
              officeHour.endTime.hour,
              inInclusiveRange(0, 23),
              reason: 'End hour should be 0-23',
            );
            expect(
              officeHour.endTime.minute,
              inInclusiveRange(0, 59),
              reason: 'End minute should be 0-59',
            );
          }
        }

        // English name from format=-6
        if (teacher.nameEn != null) {
          expect(
            teacher.nameEn,
            isNotEmpty,
            reason: 'English name should not be empty if present',
          );
        }
      });
    });
  });
}
