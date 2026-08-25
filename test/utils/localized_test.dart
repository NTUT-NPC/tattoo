import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/utils/localized.dart';

void main() {
  group('localized', () {
    group('when locale is zhTw', () {
      setUp(() async => LocaleSettings.setLocale(.zhTw));

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
      setUp(() async => LocaleSettings.setLocale(.enUs));

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

  group('tryLocalizeSyllabusSectionTitle', () {
    const englishTitles = {
      '課程大綱': 'Course Objective',
      '課程進度': 'Course Schedule',
      '評量方式與標準': 'Evaluation and grading policy',
      '使用教材、參考書目或其他': 'Materials',
      '課程諮詢管道': 'The access to curricular consultation',
      '延伸教學與資源': 'Expanding teaching and resources',
      '課程對應SDGs指標': 'The course corresponds to the SDGs',
      '課程是否導入AI': 'Does the course incorporate AI',
      '備註': 'Note',
    };

    test('localizes every known title in zh-TW', () async {
      await LocaleSettings.setLocale(.zhTw);

      for (final title in englishTitles.keys) {
        expect(tryLocalizeSyllabusSectionTitle(title), title);
      }
    });

    test('localizes every known title in en-US', () async {
      await LocaleSettings.setLocale(.enUs);

      for (final entry in englishTitles.entries) {
        expect(tryLocalizeSyllabusSectionTitle(entry.key), entry.value);
      }
    });

    test('preserves a normalized schedule week range', () async {
      await LocaleSettings.setLocale(.enUs);

      expect(
        tryLocalizeSyllabusSectionTitle(' 課程 進度 ( 1-16 週 ) '),
        'Course Schedule (Week 1-16)',
      );
    });

    test('returns null so unknown titles fall back to raw text', () {
      const title = '校方新增欄位';

      expect(tryLocalizeSyllabusSectionTitle(title) ?? title, title);
    });
  });
}
