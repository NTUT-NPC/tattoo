import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:tattoo/database/schema.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/models/score.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    // Base tables
    Students,
    Semesters,
    Courses,
    Departments,
    Teachers,
    Classes,
    Classrooms,
    // Tables with foreign keys to base tables
    Users,
    CourseOfferings,
    // Junction tables and dependent tables
    CourseOfferingTeachers,
    CourseOfferingClasses,
    CourseOfferingClassrooms,
    CourseOfferingStudents,
    Schedules,
    Materials,
    TeacherOfficeHours,
    Scores,
    StudentSemesterSummaries,
  ],
)
class AppDatabase extends _$AppDatabase {
  // After generating code, this class needs to define a `schemaVersion` getter
  // and a constructor telling drift where the database should be stored.
  // These are described in the getting started guide: https://drift.simonbinder.eu/setup/
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'tattoo');
  }
}
