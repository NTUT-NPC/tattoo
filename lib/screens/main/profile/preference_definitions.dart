import 'package:flutter/material.dart';
import 'package:tattoo/i18n/strings.g.dart';

enum PreferenceDetailId { language, themeMode }

typedef PreferenceDetailOption = ({
  String value,
  IconData icon,
  String title,
});

typedef PreferenceDetailGuide = ({
  IconData icon,
  String title,
  String description,
  String buttonLabel,
});

class PreferenceDetailDefinition {
  const PreferenceDetailDefinition({
    required this.title,
    this.options = const [],
    this.guide,
    required this.loadError,
    required this.saveError,
    this.actionError,
  });

  final String title;
  final List<PreferenceDetailOption> options;
  final PreferenceDetailGuide? guide;
  final String loadError;
  final String saveError;
  final String? actionError;
}

PreferenceDetailDefinition preferenceDetailDefinition(
  PreferenceDetailId id,
  Translations strings,
) {
  final preferences = strings.preferences;
  return switch (id) {
    .language => PreferenceDetailDefinition(
      title: preferences.language.title,
      options: [
        (
          value: 'system',
          icon: Icons.translate,
          title: preferences.language.followSystem,
        ),
        (
          value: 'zh-TW',
          icon: Icons.translate,
          title: preferences.language.traditionalChinese,
        ),
        (
          value: 'en-US',
          icon: Icons.translate,
          title: preferences.language.english,
        ),
      ],
      guide: (
        icon: Icons.language_outlined,
        title: preferences.language.iosGuideTitle,
        description: preferences.language.iosGuideDescription,
        buttonLabel: preferences.language.openSettings,
      ),
      loadError: preferences.language.changeFailed,
      saveError: preferences.language.changeFailed,
      actionError: preferences.language.openFailed,
    ),
    .themeMode => PreferenceDetailDefinition(
      title: preferences.darkMode,
      options: [
        (
          value: 'system',
          icon: Icons.brightness_auto_outlined,
          title: preferences.themeMode.system,
        ),
        (
          value: 'light',
          icon: Icons.light_mode_outlined,
          title: preferences.themeMode.light,
        ),
        (
          value: 'dark',
          icon: Icons.dark_mode_outlined,
          title: preferences.themeMode.dark,
        ),
      ],
      loadError: preferences.loadFailed,
      saveError: preferences.saveFailed,
    ),
  };
}
