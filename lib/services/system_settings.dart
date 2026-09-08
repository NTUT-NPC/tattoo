import 'package:flutter/services.dart';

typedef AppLanguageSettings = ({String? languageTag, bool isSystemManaged});

/// Opens operating-system settings pages that cannot be reached with a URL.
abstract final class SystemSettings {
  static const _channel = MethodChannel('club.ntut.tattoo/system_settings');

  /// Reads the Android app-language selection.
  ///
  /// Android 13 and newer return the system-managed per-app language. Older
  /// versions return TAT's device-local fallback selection.
  static Future<AppLanguageSettings> getAppLanguage() async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'getAppLanguage',
    );
    return (
      languageTag: result?['languageTag'] as String?,
      isSystemManaged: result?['isSystemManaged'] as bool? ?? false,
    );
  }

  /// Sets the Android app language, or clears it to follow the system.
  static Future<AppLanguageSettings> setAppLanguage(String? languageTag) async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'setAppLanguage',
      {'languageTag': languageTag},
    );
    return (
      languageTag: result?['languageTag'] as String?,
      isSystemManaged: result?['isSystemManaged'] as bool? ?? false,
    );
  }

  /// Opens the system-managed language settings for TAT.
  static Future<void> openLanguageSettings() =>
      _channel.invokeMethod<void>('openLanguageSettings');
}
