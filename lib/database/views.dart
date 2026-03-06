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
        // TODO: Add classrooms.nameEn — English page uses abbreviated format
        // (e.g., "TB2_201") with a separate building legend table. Need to
        // parse the legend and store both short and full English names.
        classroomNameZh,
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
