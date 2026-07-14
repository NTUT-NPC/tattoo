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

/// Joins [UserSemesterSummaries] with [Semesters] for score-screen summaries.
abstract class UserAcademicSummaries extends View {
  UserSemesterSummaries get userSemesterSummaries;
  Semesters get semesters;

  @override
  Query as() =>
      select([
        userSemesterSummaries.id,
        userSemesterSummaries.user,
        userSemesterSummaries.semester,
        semesters.year,
        semesters.term,
        userSemesterSummaries.average,
        userSemesterSummaries.conduct,
        userSemesterSummaries.totalCredits,
        userSemesterSummaries.creditsPassed,
        userSemesterSummaries.note,
        userSemesterSummaries.gpa,
      ]).from(userSemesterSummaries).join([
        innerJoin(
          semesters,
          semesters.id.equalsExp(userSemesterSummaries.semester),
        ),
      ]);
}

/// Flat view of score entries with course and offering metadata.
///
/// One row per score entry. Joins [Scores] with [Courses] and optionally
/// [CourseOfferings] to provide course name and offering number for display.
///
/// Prefers the offering's timetable name; falls back to the catalog name
/// for waivers/transfers (no offering).
abstract class ScoreDetails extends View {
  Scores get scores;
  Courses get courses;
  CourseOfferings get courseOfferings;

  Expression<String> get nameZh =>
      coalesce([courseOfferings.nameZh, courses.nameZh]);
  Expression<String> get nameEn =>
      coalesce([courseOfferings.nameEn, courses.nameEn]);

  @override
  Query as() =>
      select([
        scores.id,
        scores.user,
        scores.semester,
        scores.score,
        scores.status,
        courses.code,
        nameZh,
        nameEn,
        courseOfferings.number,
      ]).from(scores).join([
        innerJoin(courses, courses.id.equalsExp(scores.course)),
        leftOuterJoin(
          courseOfferings,
          courseOfferings.id.equalsExp(scores.courseOffering),
        ),
      ]);
}

/// Flat view of a course offering joined with its catalog entry.
///
/// One row per [CourseOfferings] row. The repository composes this row with
/// separate queries for the offering's many-side relations (schedule slots,
/// teachers, classes) into a full detail record.
abstract class CourseOfferingOverviews extends View {
  CourseOfferings get courseOfferings;
  Courses get courses;

  /// Prefers the offering's timetable value; falls back to the catalog value
  /// when the offering's value is null. Always returns the offering's name in
  /// Chinese, since [CourseOfferings.nameZh] is NOT NULL.
  Expression<String> get nameZh =>
      coalesce([courseOfferings.nameZh, courses.nameZh]);
  Expression<String> get nameEn =>
      coalesce([courseOfferings.nameEn, courses.nameEn]);
  Expression<double> get credits =>
      coalesce([courseOfferings.credits, courses.credits]);
  Expression<int> get hours => coalesce([courseOfferings.hours, courses.hours]);

  @override
  Query as() =>
      select([
        courseOfferings.id,
        courseOfferings.courseCode,
        courseOfferings.semester,
        courseOfferings.number,
        nameZh,
        nameEn,
        credits,
        hours,
        courseOfferings.phase,
        courseOfferings.courseType,
        courseOfferings.status,
        courseOfferings.language,
        courseOfferings.remarks,
        courseOfferings.enrolled,
        courseOfferings.withdrawn,
        courseOfferings.fetchedAt,
      ]).from(courseOfferings).join([
        leftOuterJoin(
          courses,
          courses.code.equalsExp(courseOfferings.courseCode),
        ),
      ]);
}

/// Flat view of schedule slots with course offering and course metadata.
///
/// One row per `(dayOfWeek, period)` slot. Repository groups these rows
/// into [CourseTableCell] maps for the course table UI.
abstract class CourseTableSlots extends View {
  Schedules get schedules;
  CourseOfferings get courseOfferings;
  Courses get courses;
  Classrooms get classrooms;

  /// Prefers the offering's timetable value; falls back to the catalog value
  /// when the offering's value is null. Always returns the offering's name in
  /// Chinese, since [CourseOfferings.nameZh] is NOT NULL.
  Expression<String> get nameZh =>
      coalesce([courseOfferings.nameZh, courses.nameZh]);
  Expression<String> get nameEn =>
      coalesce([courseOfferings.nameEn, courses.nameEn]);
  Expression<double> get credits =>
      coalesce([courseOfferings.credits, courses.credits]);
  Expression<int> get hours => coalesce([courseOfferings.hours, courses.hours]);

  Expression<String> get classroomNameZh => classrooms.nameZh;
  Expression<String> get classroomNameEn => classrooms.nameEn;

  @override
  Query as() =>
      select([
        courseOfferings.id,
        courseOfferings.number,
        courseOfferings.semester,
        nameZh,
        nameEn,
        credits,
        hours,
        schedules.dayOfWeek,
        schedules.period,
        classroomNameZh,
        classroomNameEn,
      ]).from(schedules).join([
        innerJoin(
          courseOfferings,
          courseOfferings.id.equalsExp(schedules.courseOffering),
        ),
        leftOuterJoin(
          courses,
          courses.code.equalsExp(courseOfferings.courseCode),
        ),
        leftOuterJoin(
          classrooms,
          classrooms.id.equalsExp(schedules.classroom),
        ),
      ]);
}
