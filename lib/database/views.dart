import 'package:drift/drift.dart';
import 'package:tattoo/database/schema.dart';

/// Joins [UserSemesterSummaries] with [Semesters] to provide registration
/// details (class name, enrollment status) alongside semester year/term.
abstract class UserRegistrations extends View {
  UserSemesterSummaries get userSemesterSummaries;
  Semesters get semesters;

  @override
  Query as() =>
      select([
        semesters.year,
        semesters.term,
        userSemesterSummaries.className,
        userSemesterSummaries.enrollmentStatus,
      ]).from(userSemesterSummaries).join([
        innerJoin(
          semesters,
          semesters.id.equalsExp(userSemesterSummaries.semester),
        ),
      ]);
}
