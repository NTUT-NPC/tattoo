import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global toggle for Firebase features.
///
/// This constant determines if Firebase should be initialized in `main.dart`
/// and if [AnalyticsService] should expose a real [FirebaseAnalytics] instance.
///
/// Defaults to `true` only in release mode to avoid package name mismatch
/// issues in debug mode (`club.ntut.tattoo.debug`).
///
/// Can be overridden via: `--dart-define=USE_FIREBASE=true`
const bool useFirebase = bool.fromEnvironment(
  'USE_FIREBASE',
  defaultValue: kReleaseMode,
);

/// Provider for the [AnalyticsService].
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// A wrapper service for Firebase Analytics.
///
/// Exposes a nullable [instance] that returns [FirebaseAnalytics] when
/// [useFirebase] is true, or `null` when disabled. Callers use null-aware
/// access to safely call any analytics method:
///
/// ```dart
/// ref.read(analyticsServiceProvider).instance?.logAppOpen();
/// ```
class AnalyticsService {
  /// The [FirebaseAnalytics] instance, or `null` if Firebase is disabled.
  FirebaseAnalytics? get instance =>
      useFirebase ? FirebaseAnalytics.instance : null;
}
