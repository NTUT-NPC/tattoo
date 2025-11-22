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
  title: json['title'] as String?,
  href: json['href'] as String?,
);

Map<String, dynamic> _$ISchoolPlusMaterialRefToJson(
  _ISchoolPlusMaterialRef instance,
) => <String, dynamic>{'title': instance.title, 'href': instance.href};
