import 'package:drift/drift.dart';
import 'package:tattoo/database/database.dart';

/// Reusable database operations shared across repositories.
extension DatabaseActions on AppDatabase {
  /// Returns the ID of an existing semester row, or creates one if missing.
  Future<int> getOrCreateSemester(int year, int term) async {
    return (await into(semesters).insertReturning(
      SemestersCompanion.insert(year: year, term: term),
      onConflict: DoUpdate(
        (old) => SemestersCompanion(year: Value(year), term: Value(term)),
        target: [semesters.year, semesters.term],
      ),
    )).id;
  }

  /// Clears all app data in local database tables.
  Future<void> clearAllData({bool preserveAccount = true}) async {
    await transaction(() async {
      await customStatement('PRAGMA foreign_keys = OFF');
      for (final table in allTables) {
        if (preserveAccount && table.actualTableName == users.actualTableName) {
          continue;
        }
        await delete(table).go();
      }
      await customStatement('PRAGMA foreign_keys = ON');
    });
  }
}
