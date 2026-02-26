import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global toggle for Firebase features.
///
/// This constant determines if Firebase should be initialized in `main.dart`
/// and if [AnalyticsService] should send real events.
///
/// Defaults to `true` only in release mode to avoid package name mismatch
/// issues in debug mode (`club.ntut.tattoo.debug`).
///
/// Can be overridden via: `--dart-define=USE_FIREBASE=true`
const bool useFirebase = bool.fromEnvironment('USE_FIREBASE', defaultValue: kReleaseMode);

/// Provider for the [AnalyticsService].
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// A wrapper service for Firebase Analytics.
///
/// This service handles the global [useFirebase] toggle internally. If Firebase
/// is disabled, calls to this service are safe and will only print to the 
/// debug console.
class AnalyticsService {
  /// Logs a custom event. 
  /// 
  /// This is a no-op (logs to console only) if [useFirebase] is false.
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!useFirebase) {
      _logDebug('logEvent: $name ($parameters)');
      return;
    }
    await FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
  }

  /// Logs the `app_open` event.
  /// 
  /// This is a no-op if [useFirebase] is false.
  Future<void> logAppOpen() async {
    if (!useFirebase) {
      _logDebug('logAppOpen');
      return;
    }
    await FirebaseAnalytics.instance.logAppOpen();
  }

  void _logDebug(String message) {
    debugPrint('[Analytics Service] $message');
  }
}
