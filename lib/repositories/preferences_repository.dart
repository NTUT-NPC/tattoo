import 'package:tattoo/database/database.dart';
import 'package:riverpod/riverpod.dart';

/// Provides the [PreferencesRepository] instance.
final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository(
    db: ref.watch(databaseProvider),
  );
});

/// Manages app preferences: demo mode, color customizations, onboarding status.
class PreferencesRepository {
  final AppDatabase _db;

  PreferencesRepository({
    required AppDatabase db,
  }) : _db = db;

  Future<void> clearDatabase() async {
    await _db.clearAllData(preserveAccount: false);
  }
}
