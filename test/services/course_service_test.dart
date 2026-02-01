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

      // Authenticate before each test
      // This ensures we have valid session even if previous test cleared cookies
      await portalService.login(
        TestCredentials.username,
        TestCredentials.password,
      );
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
          expect(semester.semester, isNotNull);
          expect(
            semester.year,
            greaterThan(80),
            reason: 'ROC year should be from modern era (>80 means after 1991)',
          );
          expect(
            semester.semester,
            isIn([1, 2]),
            reason: 'Semester should be 1 (fall) or 2 (spring)',
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
          semester: semesters.first,
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
          semester: semesters.first,
        );

        // Find a real course (not special rows like 班週會及導師時間)
        // Real courses have a course number
        final regularCourses = courseTable.where(
          (schedule) => schedule.number != null && schedule.number!.isNotEmpty,
        );

        expect(
          regularCourses,
          isNotEmpty,
          reason: 'Should have at least one regular course with a number',
        );

        final firstRegularCourse = regularCourses.first;

        // Verify required fields are present for regular courses
        expect(firstRegularCourse.number, isNotEmpty);
        expect(firstRegularCourse.course?.name, isNotNull);
        expect(firstRegularCourse.course?.name, isNotEmpty);

        // Verify numeric fields have reasonable values
        if (firstRegularCourse.credits != null) {
          expect(firstRegularCourse.credits, greaterThan(0));
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
          semester: semesters.first,
        );

        final coursesWithNames = courseTable.where(
          (schedule) => schedule.course?.name != null,
        );

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
          semester: semesters.first,
        );

        final coursesWithSchedule = courseTable.where(
          (schedule) =>
              schedule.schedule != null && schedule.schedule!.isNotEmpty,
        );

        expect(
          coursesWithSchedule,
          isNotEmpty,
          reason: 'At least one course should have a schedule',
        );

        // Verify schedule structure is valid (enums are guaranteed by type system)
      });

      test('should parse course types correctly', () async {
        final semesters = await courseService.getCourseSemesterList(
          TestCredentials.username,
        );
        final courseTable = await courseService.getCourseTable(
          username: TestCredentials.username,
          semester: semesters.first,
        );

        final coursesWithType = courseTable.where(
          (schedule) => schedule.type != null,
        );

        expect(
          coursesWithType,
          isNotEmpty,
          reason: 'At least one course should have a type',
        );

        for (final course in coursesWithType) {
          expect(
            course.type,
            isIn([
              CourseType.required,
              CourseType.elective,
              CourseType.general,
            ]),
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
          semester: semesters.first,
        );

        final courseWithId = courseTable.firstWhere(
          (schedule) => schedule.course?.id != null,
        );

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
  });
}
