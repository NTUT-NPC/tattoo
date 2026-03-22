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
    Materials,
    TeacherSemesters,
    TeacherOfficeHours,
    Scores,
    UserSemesterSummaries,
    UserSemesterSummaryTutors,
    UserSemesterSummaryCadreRoles,
    UserSemesterRankings,
  ],
  views: [
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
    return driftDatabase(name: 'tattoo').interceptWith(_LogInterceptor());
  }
}

class _LogInterceptor extends QueryInterceptor {
  static final _fromPattern = RegExp(r'FROM "(\w+)"', caseSensitive: false);
  static final _firstQuoted = RegExp(r'"(\w+)"');

  static String _describeStatement(String statement) {
    final verb = statement.split(' ').first;
    final table =
        _fromPattern.firstMatch(statement)?.group(1) ??
        _firstQuoted.firstMatch(statement)?.group(1) ??
        '?';
    return '$verb $table';
  }

  Future<T> _run<T>(
    Future<T> Function() op,
    String statement,
    List<Object?> args, [
    String Function(T result)? describeResult,
  ]) async {
    final result = await op();
    final desc = _describeStatement(statement);
    final parts = [
      desc,
      if (args.isNotEmpty) '${args.length} arg${args.length != 1 ? 's' : ''}',
      if (describeResult != null) describeResult(result),
    ];
    log(parts.join(' '), name: 'DB');
    return result;
  }

  @override
  Future<void> runCustom(
    QueryExecutor e,
    String statement,
    List<Object?> args,
  ) => _run(() => e.runCustom(statement, args), statement, args);

  @override
  Future<int> runInsert(
    QueryExecutor e,
    String statement,
    List<Object?> args,
  ) => _run(() => e.runInsert(statement, args), statement, args);

  @override
  Future<int> runUpdate(
    QueryExecutor e,
    String statement,
    List<Object?> args,
  ) => _run(() => e.runUpdate(statement, args), statement, args);

  @override
  Future<int> runDelete(
    QueryExecutor e,
    String statement,
    List<Object?> args,
  ) => _run(() => e.runDelete(statement, args), statement, args);

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor e,
    String statement,
    List<Object?> args,
  ) => _run(
    () => e.runSelect(statement, args),
    statement,
    args,
    (rows) => '=> ${rows.length} row${rows.length != 1 ? 's' : ''}',
  );
}
