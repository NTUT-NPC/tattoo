import '../i18n/strings.g.dart';

/// Picks the appropriate localized string based on the current app locale.
///
/// NTUT services return Chinese (always) and English (sometimes). For Chinese
/// locales, prefers [zh]; all other locales prefer [en], falling back to [zh].
String localized(String? zh, String? en) {
  if (LocaleSettings.currentLocale == AppLocale.zhTw) {
    return zh ?? en ?? '';
  }
  return en ?? zh ?? '';
}
