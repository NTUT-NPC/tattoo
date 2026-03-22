import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Global toggle for Firebase features.
///
/// Defaults to `false` to avoid package name mismatch issues in debug mode
/// (`club.ntut.tattoo.debug`). Override via: `--dart-define=USE_FIREBASE=true`
const bool useFirebase = bool.fromEnvironment(
  'USE_FIREBASE',
  defaultValue: false,
);

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

  /// Logs a custom message to Firebase Crashlytics if enabled.
  ///
  /// These logs appear in the "Logs" tab of a crash report and help provide
  /// context for what happened leading up to a crash.
  void log(String message) {
    crashlytics?.log(message);
  }
}

/// Global [FirebaseService] instance.
var firebase = const FirebaseService();
