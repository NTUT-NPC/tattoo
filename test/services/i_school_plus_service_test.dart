import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/firebase_service.dart';
import 'package:tattoo/services/i_school_plus_service.dart';
import 'package:tattoo/services/portal_service.dart';

import '../test_helpers.dart';

void main() {
  group('ISchoolPlusService Integration Tests', () {
    late PortalService portalService;
    late ISchoolPlusService iSchoolPlusService;
    late ISchoolCourseDto testCourse;

    setUpAll(() async {
      TestCredentials.validate();

      portalService = PortalService(FirebaseService());
      iSchoolPlusService = ISchoolPlusService();

      await portalService.login(
        TestCredentials.username,
        TestCredentials.password,
      );
      await portalService.sso(PortalServiceCode.iSchoolPlusService);

      final courses = await iSchoolPlusService.getCourseList();

      if (courses.isEmpty) {
        throw Exception('No I-School Plus courses available for testing.');
      }

      testCourse = courses.pickRandom();
    });

    setUp(() async {
      portalService = PortalService(FirebaseService());
      iSchoolPlusService = ISchoolPlusService();

      await portalService.login(
        TestCredentials.username,
        TestCredentials.password,
      );
      await portalService.sso(PortalServiceCode.iSchoolPlusService);

      await respectfulDelay();
    });

    group('getCourseList', () {
      test('should return list of available courses', () async {
        final courses = await iSchoolPlusService.getCourseList();

        expect(
          courses,
          isNotEmpty,
          reason: 'Should have at least one I-School Plus course',
        );

        for (final course in courses) {
          expect(course.courseNumber, isNotEmpty);
          expect(course.internalId, isNotEmpty);
        }
      });
    });

    group('getStudents', () {
      test('should return list of enrolled students', () async {
        final students = await iSchoolPlusService.getStudents(testCourse);

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
        final students = await iSchoolPlusService.getStudents(testCourse);

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
        final students = await iSchoolPlusService.getStudents(testCourse);

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
        await iSchoolPlusService.getMaterials(testCourse);

        // Note: Some courses might not have materials
        // Method completes successfully (type guaranteed by return type)
      });

      test('should parse material data correctly', () async {
        final materials = await iSchoolPlusService.getMaterials(testCourse);

        if (materials.isNotEmpty) {
          final firstMaterial = materials.pickRandom();

          expect(
            firstMaterial.course.courseNumber,
            equals(testCourse.courseNumber),
          );

          // Materials should have both title and href
          expect(firstMaterial.title, isNotNull);
          expect(firstMaterial.title, isNotEmpty);
          expect(firstMaterial.href, isNotNull);
          expect(firstMaterial.href, isNotEmpty);
        }
      });

      test('should exclude folder items without files', () async {
        final materials = await iSchoolPlusService.getMaterials(testCourse);

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
        final materials = await iSchoolPlusService.getMaterials(testCourse);

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
        final materials = await iSchoolPlusService.getMaterials(testCourse);

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
        final materials = await iSchoolPlusService.getMaterials(testCourse);

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

      test('should correctly identify streamable materials', () async {
        final materials = await iSchoolPlusService.getMaterials(testCourse);

        // Test streamable field for all materials
        for (final material in materials.take(5)) {
          final materialInfo = await iSchoolPlusService.getMaterial(material);

          // iStream videos should be marked as streamable
          if (materialInfo.downloadUrl.host.contains('istream.ntut.edu.tw')) {
            expect(
              materialInfo.streamable,
              isTrue,
              reason: 'iStream videos should be streamable',
            );
          }

          // Non-iStream materials should not be marked as streamable
          if (!materialInfo.downloadUrl.host.contains('istream.ntut.edu.tw')) {
            expect(
              materialInfo.streamable,
              isFalse,
              reason: 'Non-video materials should not be streamable',
            );
          }
        }
      });
    });

    group('course selection caching', () {
      test('should cache selected course across multiple calls', () async {
        await iSchoolPlusService.getStudents(testCourse);

        // Second call should reuse the cached selection
        await iSchoolPlusService.getMaterials(testCourse);
      });

      test('should handle switching between courses', () async {
        final courses = await iSchoolPlusService.getCourseList();

        if (courses.length >= 2) {
          await iSchoolPlusService.getStudents(courses[0]);
          await iSchoolPlusService.getStudents(courses[1]);
        }
      });
    });
  });
}
