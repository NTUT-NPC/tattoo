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

  /// Initializes Firebase Remote Config.
  ///
  /// Call this at app start to fetch and activate the latest configuration.
  Future<void> init() async {
    final rc = remoteConfig;
    if (rc == null) return;

    await _fetchAndActivate(
      rc,
      context: 'initialized',
      setupSettings: true,
    );
  }

  /// Forces a fresh fetch and activation of Remote Config.
  Future<void> fetch() async {
    final rc = remoteConfig;
    if (rc == null) return;

    await _fetchAndActivate(
      rc,
      context: 'forced fetch',
      recordFatalOnFailure: true,
    );
  }

  Future<void> _fetchAndActivate(
    FirebaseRemoteConfig rc, {
    required String context,
    bool setupSettings = false,
    bool recordFatalOnFailure = false,
  }) async {
    try {
      if (setupSettings) {
        await rc.setConfigSettings(
          RemoteConfigSettings(
            fetchTimeout: const Duration(minutes: 1),
            minimumFetchInterval: const Duration(minutes: 1),
          ),
        );
      }

      await rc.fetchAndActivate();

      final configData = rc.getAll().map(
        (key, value) => MapEntry(key, value.asString()),
      );

      if (rc.lastFetchStatus == RemoteConfigFetchStatus.success) {
        final message = 'Remote Config $context successful: $configData';
        dev.log(message, name: 'FirebaseService');
        firebaseService.log(message);
      } else {
        final message =
            'Remote Config $context failed (status: ${rc.lastFetchStatus}), using cache: $configData';
        dev.log(message, name: 'FirebaseService');
        firebaseService.log(message);
      }
    } catch (e) {
      final configData = rc.getAll().map(
        (key, value) => MapEntry(key, value.asString()),
      );
      final message =
          'Remote Config $context error: $e. Using cache: $configData';
      dev.log(message, name: 'FirebaseService');

      if (recordFatalOnFailure) {
        firebaseService.recordNonFatal(message);
      } else {
        firebaseService.log(message);
      }
    }
  }

  /// Retrieves a summary of a Remote Config string value.
  ///
  /// Returns a record containing the string value and whether it came from
  /// a remote source.
  ({String value, bool isRemote}) getRemoteConfigString(String key) {
    final rc = remoteConfig;
    if (rc == null) {
      return (value: '', isRemote: false);
    }
    final val = rc.getValue(key);
    return (
      value: val.asString(),
      isRemote: val.source == ValueSource.valueRemote,
    );
  }
}
