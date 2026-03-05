import 'package:drift/drift.dart';
import 'package:tattoo/database/database.dart';

/// Reusable database operations shared across repositories.
extension DatabaseActions on AppDatabase {
  /// Drops and recreates all tables, fully resetting the database.
  Future<void> deleteEverything() async {
    final m = Migrator(this);
    final reversed = allSchemaEntities.toList().reversed;
    for (final entity in reversed) {
      await m.drop(entity);
    }
    await m.createAll();
  }

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
}
