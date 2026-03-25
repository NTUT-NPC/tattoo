import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'dart:developer' as dev;

/// Global toggle for Firebase features.
///
/// Defaults to `false` to avoid package name mismatch issues in debug mode
/// (`club.ntut.tattoo.debug`). Override via: `--dart-define=USE_FIREBASE=true`
const bool useFirebase = bool.fromEnvironment(
  'USE_FIREBASE',
  defaultValue: false,
);

/// Global [FirebaseService] instance.
var firebaseService = const FirebaseService();

/// Unified service for Firebase Analytics and Crashlytics.
///
/// Exposes nullable getters that return real instances when [useFirebase] is
/// true, or `null` when disabled. Callers use null-aware access:
///
/// ```dart
/// firebase.analytics?.logAppOpen();
/// firebase.crashlytics?.recordError(e, stack);
/// ```
class FirebaseService {
  const FirebaseService();

  /// The [FirebaseAnalytics] instance, or `null` if Firebase is disabled.
  FirebaseAnalytics? get analytics =>
      useFirebase ? FirebaseAnalytics.instance : null;

  /// Returns a [FirebaseAnalyticsObserver] for use with navigation observers, or
  /// `null` if Firebase is disabled.
  FirebaseAnalyticsObserver? get analyticsObserver =>
      useFirebase ? FirebaseAnalyticsObserver(analytics: analytics!) : null;

  /// The [FirebaseCrashlytics] instance, or `null` if Firebase is disabled.
  FirebaseCrashlytics? get crashlytics =>
      useFirebase ? FirebaseCrashlytics.instance : null;

  /// The [FirebaseRemoteConfig] instance, or `null` if Firebase is disabled.
  FirebaseRemoteConfig? get remoteConfig =>
      useFirebase ? FirebaseRemoteConfig.instance : null;

  /// Logs a custom message to Firebase Crashlytics if enabled.
  ///
  /// These logs appear in the "Logs" tab of a crash report and help provide
  /// context for what happened leading up to a crash.
  void log(String message) {
    crashlytics?.log(message);
  }

  /// Records a non-fatal error to Firebase Crashlytics if enabled.
  void recordNonFatal(String message) {
    crashlytics?.recordError(
      Exception(message),
      StackTrace.current,
      fatal: false,
    );
  }

  /// Retrieves a string value from Remote Config.
  /// Handles initializing the remote config settings and fetching.
  Future<String?> fetchRemoteConfigString(String key) async {
    final rc = remoteConfig;
    if (rc == null) return null;

    try {
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(minutes: 1),
        ),
      );
      await rc.fetchAndActivate();
      final result = rc.getString(key);
      dev.log(
        'Fetched Remote Config for "$key":\n$result',
        name: 'FirebaseService',
      );
      firebaseService.log('Fetched Remote Config for "$key":\n$result');
      return result;
    } catch (e) {
      dev.log('Remote config fetch failed: $e');
      firebaseService.recordNonFatal('Remote config fetch failed: $e');
      return null;
    }
  }
}
