import 'package:tattoo/i18n/strings.g.dart';

final _syllabusTitleWhitespacePattern = RegExp(r'\s+');
final _syllabusScheduleTitlePattern = RegExp(
  r'^課程進度(?:\(([^()]+)週\))?$',
);

/// Picks the appropriate localized string based on the current app locale.
///
/// NTUT services return Chinese (always) and English (sometimes). For Chinese
/// locales, prefers [zh]; all other locales prefer [en], falling back to [zh].
String localized(String? zh, String? en) {
  if (LocaleSettings.currentLocale == .zhTw) {
    return zh ?? en ?? '';
  }
  return en ?? zh ?? '';
}

/// Localizes a known raw syllabus section title from NTUT.
///
/// Unknown titles return null so callers can preserve and display the source
/// title with `tryLocalizeSyllabusSectionTitle(title) ?? title`.
String? tryLocalizeSyllabusSectionTitle(String rawTitle) {
  final title = rawTitle.replaceAll(_syllabusTitleWhitespacePattern, '');
  final sections = t.courseTable.syllabus.sections;
  if (_syllabusScheduleTitlePattern.firstMatch(title) case final match?) {
    if (match.group(1) case final weeks?) {
      return sections.scheduleWithWeeks(weeks: weeks);
    }
    return sections.schedule;
  }

  return switch (title) {
    '課程大綱' => sections.objective,
    '評量方式與標準' => sections.evaluation,
    '使用教材、參考書目或其他' => sections.materials,
    '課程諮詢管道' => sections.consultation,
    '延伸教學與資源' => sections.resources,
    '課程對應SDGs指標' => sections.sdgs,
    '課程是否導入AI' => sections.ai,
    '備註' => sections.note,
    _ => null,
  };
}
