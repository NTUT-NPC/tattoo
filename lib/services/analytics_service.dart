import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/services/firebase_service.dart';

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
