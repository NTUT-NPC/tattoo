import 'package:drift/drift.dart';
import 'package:tattoo/database/database.dart';

/// Reusable database operations shared across repositories.
extension DatabaseActions on AppDatabase {
  /// Drops and recreates all tables, fully resetting the database.
  Future<void> deleteEverything() async {
    await transaction(() async {
      final m = Migrator(this);
      final reversed = allSchemaEntities.toList().reversed;
      for (final entity in reversed) {
        await m.drop(entity);
      }
      await m.createAll();
    });
  }

  /// Returns an existing semester row, or creates one if missing.
  ///
  /// When [inCourseSemesterList] is `true`, marks the semester as having
  /// appeared in the course semester list API response.
  Future<Semester> getOrCreateSemester(
    int year,
    int term, {
    bool? inCourseSemesterList,
  }) async {
    final companion = SemestersCompanion.insert(
      year: year,
      term: term,
      inCourseSemesterList: Value.absentIfNull(inCourseSemesterList),
    );

    return into(semesters).insertReturning(
      companion,
      onConflict: DoUpdate(
        (old) => companion,
        target: [semesters.year, semesters.term],
      ),
    );
  }

  /// Returns the ID of an existing course row, or creates/updates one.
  Future<int> upsertCourse({
    required String code,
    required double credits,
    required int hours,
    required String nameZh,
    String? nameEn,
  }) async {
    return (await into(courses).insertReturning(
      CoursesCompanion.insert(
        code: code,
        credits: credits,
        hours: hours,
        nameZh: nameZh,
        nameEn: Value(nameEn),
      ),
      onConflict: DoUpdate(
        (old) => CoursesCompanion(
          credits: Value(credits),
          hours: Value(hours),
          nameZh: Value(nameZh),
          nameEn: Value.absentIfNull(nameEn),
        ),
        target: [courses.code],
      ),
    )).id;
  }

  /// Returns the ID of an existing teacher row, or creates/updates one.
  Future<int> upsertTeacher({
    required String code,
    required int semesterId,
    required String nameZh,
    String? nameEn,
  }) async {
    return (await into(teachers).insertReturning(
      TeachersCompanion.insert(
        code: code,
        semester: semesterId,
        nameZh: nameZh,
        nameEn: Value(nameEn),
      ),
      onConflict: DoUpdate(
        (old) => TeachersCompanion(
          nameZh: Value(nameZh),
          nameEn: Value.absentIfNull(nameEn),
        ),
        target: [teachers.code, teachers.semester],
      ),
    )).id;
  }

  /// Returns the ID of an existing classroom row, or creates one.
  Future<int> upsertClassroom({
    required String code,
    required String nameZh,
  }) async {
    return (await into(classrooms).insertReturning(
      ClassroomsCompanion.insert(code: code, nameZh: nameZh),
      onConflict: DoUpdate(
        (old) => ClassroomsCompanion(nameZh: Value(nameZh)),
        target: [classrooms.code],
      ),
    )).id;
  }

  /// Returns the ID of an existing class row, or creates one.
  Future<int> upsertClass({
    required String code,
    required int semesterId,
    required String nameZh,
    String? nameEn,
  }) async {
    return (await into(classes).insertReturning(
      ClassesCompanion.insert(
        code: code,
        semester: semesterId,
        nameZh: nameZh,
        nameEn: Value(nameEn),
      ),
      onConflict: DoUpdate(
        (old) => ClassesCompanion(
          nameZh: Value(nameZh),
          nameEn: Value.absentIfNull(nameEn),
        ),
        target: [classes.code, classes.semester],
      ),
    )).id;
  }

  /// Returns the ID of an existing course offering, or creates/updates one.
  Future<int> upsertCourseOffering({
    required int courseId,
    required int semesterId,
    required String number,
    int? phase,
    String? status,
    String? language,
    String? remarks,
    String? syllabusId,
  }) async {
    return (await into(courseOfferings).insertReturning(
      CourseOfferingsCompanion.insert(
        course: courseId,
        semester: semesterId,
        number: number,
        phase: Value(phase),
        status: Value(status),
        language: Value(language),
        remarks: Value(remarks),
        syllabusId: Value(syllabusId),
      ),
      onConflict: DoUpdate(
        (old) => CourseOfferingsCompanion(
          course: Value(courseId),
          phase: Value(phase),
          status: Value(status),
          language: Value(language),
          remarks: Value(remarks),
          syllabusId: Value(syllabusId),
        ),
        target: [courseOfferings.number],
      ),
    )).id;
  }
}
