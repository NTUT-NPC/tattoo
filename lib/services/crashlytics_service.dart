import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/services/firebase_service.dart';

/// Provider for the [CrashlyticsService].
final crashlyticsServiceProvider = Provider<CrashlyticsService>((ref) {
  return CrashlyticsService();
});

/// A wrapper service for Firebase Crashlytics.
///
/// Exposes a nullable [instance] that returns [FirebaseCrashlytics] when
/// [useFirebase] is true, or `null` when disabled. Callers use null-aware
/// access to safely call any crashlytics method:
///
/// ```dart
/// ref.read(crashlyticsServiceProvider).instance?.logError(Exception('Error'));
/// ```
class CrashlyticsService {
  /// The [FirebaseCrashlytics] instance, or `null` if Firebase is disabled.
  FirebaseCrashlytics? get instance =>
      useFirebase ? FirebaseCrashlytics.instance : null;
}
