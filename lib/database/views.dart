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
abstract class ScoreDetails extends View {
  Scores get scores;
  Courses get courses;
  CourseOfferings get courseOfferings;

  @override
  Query as() =>
      select([
        scores.id,
        scores.user,
        scores.semester,
        scores.score,
        scores.status,
        courses.code,
        courses.nameZh,
        courseOfferings.number,
      ]).from(scores).join([
        innerJoin(courses, courses.id.equalsExp(scores.course)),
        leftOuterJoin(
          courseOfferings,
          courseOfferings.id.equalsExp(scores.courseOffering),
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

  Expression<String> get classroomNameZh => classrooms.nameZh;
  Expression<String> get classroomNameEn => classrooms.nameEn;

  @override
  Query as() =>
      select([
        courseOfferings.id,
        courseOfferings.number,
        courseOfferings.semester,
        courses.nameZh,
        courses.nameEn,
        courses.credits,
        courses.hours,
        schedules.dayOfWeek,
        schedules.period,
        classroomNameZh,
        classroomNameEn,
      ]).from(schedules).join([
        innerJoin(
          courseOfferings,
          courseOfferings.id.equalsExp(schedules.courseOffering),
        ),
        innerJoin(courses, courses.id.equalsExp(courseOfferings.course)),
        leftOuterJoin(
          classrooms,
          classrooms.id.equalsExp(schedules.classroom),
        ),
      ]);
}
