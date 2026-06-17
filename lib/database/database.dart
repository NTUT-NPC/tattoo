import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/schema.dart';
import 'package:tattoo/database/views.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/models/ranking.dart';
import 'package:tattoo/models/score.dart';
import 'package:tattoo/models/user.dart';

export 'package:tattoo/database/actions.dart';

part 'database.g.dart';

/// Provides the singleton [AppDatabase] instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

@DriftDatabase(
  tables: [
    // Base tables
    Users,
    Students,
    Semesters,
    Courses,
    Departments,
    Teachers,
    Classes,
    Classrooms,
    // Tables with foreign keys to base tables
    CourseOfferings,
    // Junction tables and dependent tables
    CourseOfferingTeachers,
    CourseOfferingClasses,
    CourseOfferingStudents,
    Schedules,
    Syllabuses,
    Materials,
    TeacherSemesters,
    TeacherOfficeHours,
    Scores,
    UserSemesterSummaries,
    UserSemesterSummaryTutors,
    UserSemesterSummaryCadreRoles,
    UserSemesterRankings,
    CalendarEvents,
  ],
  views: [
    CourseOfferingOverviews,
    CourseTableSlots,
    ScoreDetails,
    UserAcademicSummaries,
    UserRegistrations,
  ],
)
class AppDatabase extends _$AppDatabase {
  // After generating code, this class needs to define a `schemaVersion` getter
  // and a constructor telling drift where the database should be stored.
  // These are described in the getting started guide: https://drift.simonbinder.eu/setup/
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: destructiveFallback.onUpgrade,
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');

      if (details.wasCreated) {
        log('Database created with schema v$schemaVersion', name: 'DB');
        return;
      }

      try {
        await validateDatabaseSchema();
        log('Database schema is up to date', name: 'DB');
      } on SchemaMismatch catch (_) {
        log('Schema mismatch detected, recreating database', name: 'DB');
        await destructiveFallback.onUpgrade(createMigrator(), 0, schemaVersion);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'tattoo');
  }
}
