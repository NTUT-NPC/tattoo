import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/services/system_settings.dart';

final languageRepositoryProvider = Provider<LanguageRepository>((ref) {
  return const LanguageRepository();
});

class LanguageRepository {
  const LanguageRepository();

  Future<String> readSelection() async {
    final settings = await SystemSettings.getAppLanguage();
    return _selectionFor(settings.languageTag);
  }

  String _selectionFor(String? languageTag) {
    return switch (languageTag) {
      final tag? when tag.startsWith('zh') => 'zh-TW',
      final tag? when tag.startsWith('en') => 'en-US',
      _ => 'system',
    };
  }

  Future<void> select(String value) async {
    final languageTag = value == 'system' ? null : value;
    final settings = await SystemSettings.setAppLanguage(languageTag);
    if (languageTag == null) {
      await LocaleSettings.useDeviceLocale();
    } else {
      await LocaleSettings.setLocaleRaw(
        languageTag,
        listenToDeviceLocale: settings.isSystemManaged,
      );
    }
  }

  Future<void> restore() async {
    if (defaultTargetPlatform != .android) {
      await LocaleSettings.useDeviceLocale();
      return;
    }

    try {
      final settings = await SystemSettings.getAppLanguage();
      final value = _selectionFor(settings.languageTag);
      if (value == 'system') {
        await LocaleSettings.useDeviceLocale();
      } else {
        await LocaleSettings.setLocaleRaw(
          value,
          listenToDeviceLocale: settings.isSystemManaged,
        );
      }
    } catch (_) {
      await LocaleSettings.useDeviceLocale();
    }
  }

  Future<void> openSystemSettings() => SystemSettings.openLanguageSettings();
}
