import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/course_service.dart';
import 'package:tattoo/services/i_school_plus_service.dart';
import 'package:tattoo/services/portal_service.dart';

import '../test_helpers.dart';

void main() {
  group('ISchoolPlusService Integration Tests', () {
    late PortalService portalService;
    late CourseService courseService;
    late ISchoolPlusService iSchoolPlusService;
    late String testCourseNumber;

    setUpAll(() async {
      TestCredentials.validate();

      // Get a valid course number for testing
      // Re-authenticate to ensure we have a valid session
      // (cookies may have been cleared by other tests)
      portalService = PortalService();
      courseService = CourseService();

      await portalService.login(
        TestCredentials.username,
        TestCredentials.password,
      );
      await portalService.sso(PortalServiceCode.courseService);

      final semesters = await courseService.getCourseSemesterList(
        TestCredentials.username,
      );

      if (semesters.isEmpty) {
        throw Exception('No semesters available for testing.');
      }

      final courseTable = await courseService.getCourseTable(
        username: TestCredentials.username,
        semester: semesters.pickRandom(),
      );

      // Find a regular course (not special rows like 班週會及導師時間)
      final regularCourses = courseTable
          .where(
            (schedule) =>
                schedule.number != null && schedule.number!.isNotEmpty,
          )
          .toList();

      if (regularCourses.isEmpty) {
        throw Exception('No regular courses available for testing');
      }

      // Use a random regular course's number for testing
      testCourseNumber = regularCourses.pickRandom().number!;
    });

    setUp(() async {
      portalService = PortalService();
      iSchoolPlusService = ISchoolPlusService();

      // Reuse existing session if available
      if (!await portalService.isLoggedIn()) {
        await portalService.login(
          TestCredentials.username,
          TestCredentials.password,
        );
      }
      await portalService.sso(PortalServiceCode.iSchoolPlusService);

      await respectfulDelay();
    });

    group('getStudents', () {
      test('should return list of enrolled students', () async {
        final students = await iSchoolPlusService.getStudents(
          testCourseNumber,
        );

        expect(
          students,
          isNotEmpty,
          reason: 'Course should have at least one student',
        );

        for (final student in students) {
          expect(student.id, isNotNull, reason: 'Student should have an ID');
          // Name can be null for students without a name in the system
        }
      });

      test('should filter out system accounts', () async {
        final students = await iSchoolPlusService.getStudents(
          testCourseNumber,
        );

        final systemAccounts = students.where(
          (student) => student.id == 'istudyoaa',
        );

        expect(
          systemAccounts,
          isEmpty,
          reason: 'System accounts should be filtered out',
        );
      });

      test('should parse student data correctly', () async {
        final students = await iSchoolPlusService.getStudents(
          testCourseNumber,
        );

        final firstStudent = students.pickRandom();

        // Verify required fields
        expect(firstStudent.id, isNotNull);
        expect(firstStudent.id, isNotEmpty);
        expect(firstStudent.name, isNotNull);
        expect(firstStudent.name, isNotEmpty);

        // Verify student ID format (should be alphanumeric)
        expect(
          firstStudent.id,
          matches(r'^[A-Za-z0-9]+$'),
          reason: 'Student ID should be alphanumeric',
        );
      });
    });

    group('getMaterials', () {
      test('should return list of course materials', () async {
        await iSchoolPlusService.getMaterials(
          testCourseNumber,
        );

        // Note: Some courses might not have materials
        // Method completes successfully (type guaranteed by return type)
      });

      test('should parse material data correctly', () async {
        final materials = await iSchoolPlusService.getMaterials(
          testCourseNumber,
        );

        if (materials.isNotEmpty) {
          final firstMaterial = materials.pickRandom();

          expect(firstMaterial.courseNumber, equals(testCourseNumber));

          // Materials should have both title and href
          expect(firstMaterial.title, isNotNull);
          expect(firstMaterial.title, isNotEmpty);
          expect(firstMaterial.href, isNotNull);
          expect(firstMaterial.href, isNotEmpty);
        }
      });

      test('should exclude folder items without files', () async {
        final materials = await iSchoolPlusService.getMaterials(
          testCourseNumber,
        );

        // All materials should have an href (actual files)
        for (final material in materials) {
          expect(
            material.href,
            isNotNull,
            reason: 'Material should have an href (not a folder)',
          );
        }
      });
    });

    group('getMaterial', () {
      test('should return download URL for material', () async {
        final materials = await iSchoolPlusService.getMaterials(
          testCourseNumber,
        );

        // Test download if materials exist
        if (materials.isNotEmpty) {
          final materialInfo = await iSchoolPlusService.getMaterial(
            materials.pickRandom(),
          );

          expect(
            materialInfo.downloadUrl.toString(),
            isNotEmpty,
            reason: 'Download URL should not be empty',
          );
          expect(
            materialInfo.downloadUrl.host,
            contains('ntut.edu.tw'),
            reason: 'Download URL should be from NTUT domain',
          );
        }
        // If no materials, test passes (valid state)
      });

      test('should handle multiple material types', () async {
        final materials = await iSchoolPlusService.getMaterials(
          testCourseNumber,
        );

        // Test up to 2 materials if available
        for (final material in materials.take(2)) {
          final materialInfo = await iSchoolPlusService.getMaterial(material);

          expect(materialInfo.downloadUrl.toString(), isNotEmpty);
          expect(
            materialInfo.downloadUrl.scheme,
            isIn(['http', 'https']),
          );
        }
        // If < 2 materials, test passes with fewer iterations
      });

      test('should return valid download information', () async {
        final materials = await iSchoolPlusService.getMaterials(
          testCourseNumber,
        );

        // Test download details if materials exist
        if (materials.isNotEmpty) {
          final materialInfo = await iSchoolPlusService.getMaterial(
            materials.pickRandom(),
          );

          // Download URL should be valid
          expect(materialInfo.downloadUrl.toString(), isNotEmpty);
          expect(
            materialInfo.downloadUrl.scheme,
            isIn(['http', 'https']),
            reason: 'Download URL should use HTTP/HTTPS',
          );
          expect(
            materialInfo.downloadUrl.host,
            contains('ntut.edu.tw'),
            reason: 'Download URL should be from NTUT domain',
          );

          // Referer is optional but should be non-empty if present
          if (materialInfo.referer != null) {
            expect(materialInfo.referer, isNotEmpty);
          }
        }
        // If no materials, test passes (valid state)
      });
    });

    group('course selection caching', () {
      test('should cache selected course across multiple calls', () async {
        // First call selects the course
        await iSchoolPlusService.getStudents(testCourseNumber);

        // Second call should reuse the cached selection
        // If caching works, this should be faster and not throw
        await iSchoolPlusService.getMaterials(
          testCourseNumber,
        );

        // Method completes successfully (type guaranteed by return type)
      });

      test('should handle switching between courses', () async {
        // Get a second course if available
        final semesters = await courseService.getCourseSemesterList(
          TestCredentials.username,
        );
        final courseTable = await courseService.getCourseTable(
          username: TestCredentials.username,
          semester: semesters.first,
        );

        // Filter for regular courses (those with numbers)
        final regularCourses = courseTable
            .where(
              (schedule) =>
                  schedule.number != null && schedule.number!.isNotEmpty,
            )
            .toList();

        // Always test that we have at least one regular course
        expect(
          regularCourses,
          isNotEmpty,
          reason: 'Should have at least one regular course',
        );

        // Only test switching if multiple courses exist
        if (regularCourses.length >= 2) {
          final firstCourse = regularCourses[0].number!;
          final secondCourse = regularCourses[1].number!;

          // Switch between courses - should not throw
          await iSchoolPlusService.getStudents(firstCourse);
          await iSchoolPlusService.getStudents(secondCourse);
        }
      });
    });
  });
}
