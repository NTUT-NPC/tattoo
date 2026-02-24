import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/utils/localized.dart';

void main() {
  group('localized', () {
    group('when locale is zhTw', () {
      setUp(() async => LocaleSettings.setLocale(AppLocale.zhTw));

      test('returns zh when both provided', () {
        expect(localized('中文', 'English'), '中文');
      });

      test('falls back to en when zh is null', () {
        expect(localized(null, 'English'), 'English');
      });

      test('returns empty string when both null', () {
        expect(localized(null, null), '');
      });
    });

    group('when locale is en', () {
      setUp(() async => LocaleSettings.setLocale(AppLocale.en));

      test('returns en when both provided', () {
        expect(localized('中文', 'English'), 'English');
      });

      test('falls back to zh when en is null', () {
        expect(localized('中文', null), '中文');
      });

      test('returns empty string when both null', () {
        expect(localized(null, null), '');
      });
    });
  });
}
