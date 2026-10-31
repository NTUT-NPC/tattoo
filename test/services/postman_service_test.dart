import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/portal/ntut_portal_service.dart';
import 'package:tattoo/services/portal/portal_service.dart';
import 'package:tattoo/services/postman/ntut_postman_service.dart';
import 'package:tattoo/utils/http.dart';

import '../test_helpers.dart';

void main() {
  test('Postman rejects unauthenticated announcement requests', () async {
    final service = NtutPostmanService(dio: createDio(useCookies: false));
    await expectLater(
      service.getAnnouncements(),
      throwsA(isA<SessionExpiredException>()),
    );
    await expectLater(
      service.getAnnouncement('0'),
      throwsA(isA<SessionExpiredException>()),
    );
  });

  test('Postman paginates through the final announcement page', () async {
    TestCredentials.validate();
    final portal = NtutPortalService();
    await portal.login(TestCredentials.username, TestCredentials.password);
    await portal.sso(PortalServiceCode.postmanService.code);
    final service = NtutPostmanService();
    final first = await service.getAnnouncements();
    expect(first.page, 1);
    expect(first.totalPages, greaterThan(1));

    await respectfulDelay();
    final second = await service.getAnnouncements(page: 2);
    expect(second.page, 2);
    expect(second.totalPages, first.totalPages);
    expect(
      first.announcements
          .map((item) => item.id)
          .toSet()
          .intersection(
            second.announcements.map((item) => item.id).toSet(),
          ),
      isEmpty,
    );
    expect(
      first.announcements.last.publishedAt.isBefore(
        second.announcements.first.publishedAt,
      ),
      isFalse,
    );
    for (final item in [...first.announcements, ...second.announcements]) {
      expect(item.id, matches(r'^\d+$'));
      expect(item.category, isNotEmpty);
      expect(item.title, isNotEmpty);
      expect(item.department, isNotEmpty);
    }

    await respectfulDelay();
    final last = await service.getAnnouncements(page: first.totalPages);
    expect(last.page, last.totalPages);
    expect(last.announcements.length, inInclusiveRange(1, 10));

    await respectfulDelay();
    await expectLater(
      service.getAnnouncements(page: last.totalPages + 1),
      throwsRangeError,
    );
    await expectLater(service.getAnnouncements(page: 0), throwsRangeError);
  });

  test(
    'Postman details match list entries and reject unavailable IDs',
    () async {
      TestCredentials.validate();
      final portal = NtutPortalService();
      await portal.login(TestCredentials.username, TestCredentials.password);
      await portal.sso(PortalServiceCode.postmanService.code);
      final service = NtutPostmanService();
      final page = await service.getAnnouncements();
      for (final announcement in page.announcements.take(3)) {
        await respectfulDelay();
        final detail = await service.getAnnouncement(announcement.id);
        expect(detail.id, announcement.id);
        expect(detail.title, announcement.title);
        expect(detail.category, announcement.category);
        expect(detail.summary, isNotEmpty);
        expect(detail.contentHtml, contains('<'));
        expect(detail.contact, startsWith(announcement.department));
        expect(detail.contact, contains('\nEmail:'));
        for (final attachment in detail.attachments) {
          expect(attachment.name, isNotEmpty);
          expect(attachment.url.scheme, 'https');
          expect(attachment.url.host, 'postman.ntut.edu.tw');
          expect(attachment.url.path, '/CI/showmsg/file');
          expect(attachment.url.queryParameters['f'], isNotEmpty);
        }
      }
      await respectfulDelay();
      await expectLater(
        service.getAnnouncement('0'),
        throwsFormatException,
      );
    },
  );
}
