import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'course.freezed.dart';
part 'course.g.dart';

@freezed
abstract class EntityRef with _$EntityRef {
  const factory EntityRef({String? id, String? name}) = _EntityRef;

  factory EntityRef.fromJson(Map<String, Object?> json) =>
      _$EntityRefFromJson(json);
}

@freezed
abstract class LocalizedString with _$LocalizedString {
  const factory LocalizedString({
    String? en,
    String? zh, //
  }) = _LocalizedString;

  factory LocalizedString.fromJson(Map<String, Object?> json) =>
      _$LocalizedStringFromJson(json);
}

enum DayOfWeek {
  sunday,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
}

// 第幾節課 (1-4,N,5-9,A-D)
enum Period {
  first('1'),
  second('2'),
  third('3'),
  fourth('4'),
  nPeriod('N'),
  fifth('5'),
  sixth('6'),
  seventh('7'),
  eighth('8'),
  ninth('9'),
  aPeriod('A'),
  bPeriod('B'),
  cPeriod('C'),
  dPeriod('D');

  final String code;
  const Period(this.code);
}

enum CourseType {
  required('必'),
  elective('選'),
  general('通');

  final String code;
  const CourseType(this.code);
}

@freezed
abstract class CourseSemester with _$CourseSemester {
  const factory CourseSemester({required int year, required int semester}) =
      _CourseSemester;

  factory CourseSemester.fromJson(Map<String, Object?> json) =>
      _$CourseSemesterFromJson(json);
}

@freezed
abstract class CourseSchedule with _$CourseSchedule {
  const factory CourseSchedule({
    String? number,
    EntityRef? course,
    double? credits,
    int? hours,
    CourseType? type,
    EntityRef? teacher,
    List<EntityRef>? classes,
    List<(DayOfWeek, Period)>? schedule,
    EntityRef? classroom,
    String? status,
    String? language,
    String? syllabusId,
    String? remarks,
  }) = _CourseSchedule;

  factory CourseSchedule.fromJson(Map<String, Object?> json) =>
      _$CourseScheduleFromJson(json);
}

@freezed
abstract class Course with _$Course {
  const factory Course({
    String? id,
    LocalizedString? name,
    double? credits,
    int? hours,
    LocalizedString? description,
  }) = _Course;

  factory Course.fromJson(Map<String, Object?> json) => _$CourseFromJson(json);
}
