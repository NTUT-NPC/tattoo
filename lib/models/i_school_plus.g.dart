// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'i_school_plus.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ISchoolPlusStudent _$ISchoolPlusStudentFromJson(Map<String, dynamic> json) =>
    _ISchoolPlusStudent(
      id: json['id'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$ISchoolPlusStudentToJson(_ISchoolPlusStudent instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_ISchoolPlusMaterialRef _$ISchoolPlusMaterialRefFromJson(
  Map<String, dynamic> json,
) => _ISchoolPlusMaterialRef(
  courseNumber: json['courseNumber'] as String,
  title: json['title'] as String?,
  href: json['href'] as String?,
);

Map<String, dynamic> _$ISchoolPlusMaterialRefToJson(
  _ISchoolPlusMaterialRef instance,
) => <String, dynamic>{
  'courseNumber': instance.courseNumber,
  'title': instance.title,
  'href': instance.href,
};

_ISchoolPlusMaterial _$ISchoolPlusMaterialFromJson(Map<String, dynamic> json) =>
    _ISchoolPlusMaterial(
      downloadUrl: Uri.parse(json['downloadUrl'] as String),
      referer: json['referer'] as String?,
    );

Map<String, dynamic> _$ISchoolPlusMaterialToJson(
  _ISchoolPlusMaterial instance,
) => <String, dynamic>{
  'downloadUrl': instance.downloadUrl.toString(),
  'referer': instance.referer,
};
