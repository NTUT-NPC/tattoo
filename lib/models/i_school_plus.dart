import 'package:freezed_annotation/freezed_annotation.dart';

part 'i_school_plus.freezed.dart';
part 'i_school_plus.g.dart';

@freezed
abstract class ISchoolPlusStudent with _$ISchoolPlusStudent {
  const factory ISchoolPlusStudent({
    String? id,
    String? name, //
  }) = _ISchoolPlusStudent;

  factory ISchoolPlusStudent.fromJson(Map<String, Object?> json) =>
      _$ISchoolPlusStudentFromJson(json);
}

@freezed
abstract class ISchoolPlusMaterialRef with _$ISchoolPlusMaterialRef {
  const factory ISchoolPlusMaterialRef({
    String? title,
    String? href, //
  }) = _ISchoolPlusMaterialRef;

  factory ISchoolPlusMaterialRef.fromJson(Map<String, Object?> json) =>
      _$ISchoolPlusMaterialRefFromJson(json);
}
