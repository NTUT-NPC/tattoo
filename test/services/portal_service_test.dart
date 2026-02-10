import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/portal_service.dart';
import 'package:tattoo/utils/http.dart';

import '../test_helpers.dart';

void main() {
  group('PortalService Integration Tests', () {
    late PortalService portalService;

    setUpAll(() {
      TestCredentials.validate();
    });

    setUp(() async {
      portalService = PortalService();
      await respectfulDelay();
    });

    group('login', () {
      test('should successfully authenticate with valid credentials', () async {
        final user = await portalService.login(
          TestCredentials.username,
          TestCredentials.password,
        );

        expect(user.name, isNotNull, reason: 'User name should be returned');
        expect(
          user.email,
          contains('@ntut.edu.tw'),
          reason: 'Email should be a valid NTUT email address',
        );
      });

      test('should return complete user profile data', () async {
        final user = await portalService.login(
          TestCredentials.username,
          TestCredentials.password,
        );

        // Verify required fields are present
        expect(user.name, isNotNull, reason: 'User should have a name');
        expect(user.name, isNotEmpty);

        expect(user.email, isNotNull, reason: 'User should have an email');
        expect(
          user.email,
          contains('@ntut.edu.tw'),
          reason: 'Email should be a valid NTUT email',
        );

        // Avatar filename is optional but should be non-empty if present
        if (user.avatarFilename != null) {
          expect(user.avatarFilename, isNotEmpty);
        }

        // Password expiration should be reasonable if present
        if (user.passwordExpiresInDays != null) {
          expect(
            user.passwordExpiresInDays,
            greaterThan(0),
            reason: 'Password expiration days should be positive',
          );
        }
      });

      test('should throw exception with invalid credentials', () async {
        expect(
          () => portalService.login('invalid_user', 'invalid_pass'),
          throwsException,
        );
      });
    });

    group('getAvatar', () {
      test('should download avatar data', () async {
        final user = await portalService.login(
          TestCredentials.username,
          TestCredentials.password,
        );

        expect(
          user.avatarFilename,
          isNotNull,
          reason: 'Test account must have an avatar set',
        );
        expect(user.avatarFilename, isNotEmpty);

        final avatarData = await portalService.getAvatar(
          user.avatarFilename!,
        );

        expect(
          avatarData,
          isNotEmpty,
          reason: 'Avatar data should not be empty',
        );
      });
    });

    group('changePassword', () {
      test('should throw exception with wrong current password', () async {
        await portalService.login(
          TestCredentials.username,
          TestCredentials.password,
        );

        expect(
          () => portalService.changePassword('wrong_password', 'new_password'),
          throwsException,
        );
      });

      test('should throw exception when not logged in', () async {
        await cookieJar.deleteAll();

        expect(
          () => portalService.changePassword('any', 'any'),
          throwsException,
        );
      });
    });

    group('sso', () {
      test('should successfully authenticate with courseService', () async {
        await portalService.login(
          TestCredentials.username,
          TestCredentials.password,
        );

        // Should not throw
        await portalService.sso(PortalServiceCode.courseService);
      });

      test(
        'should successfully authenticate with iSchoolPlusService',
        () async {
          await portalService.login(
            TestCredentials.username,
            TestCredentials.password,
          );

          // Should not throw
          await portalService.sso(PortalServiceCode.iSchoolPlusService);
        },
      );

      test(
        'should successfully authenticate with studentQueryService',
        () async {
          await portalService.login(
            TestCredentials.username,
            TestCredentials.password,
          );

          // Should not throw
          await portalService.sso(PortalServiceCode.studentQueryService);
        },
      );

      test('should throw exception when cookies are cleared', () async {
        // Clear cookies to simulate not being logged in
        await cookieJar.deleteAll();

        expect(
          () => portalService.sso(PortalServiceCode.courseService),
          throwsException,
        );
      });
    });
  });
}
