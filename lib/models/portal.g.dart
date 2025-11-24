// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  name: json['name'] as String?,
  avatarFilename: json['avatarFilename'] as String?,
  email: json['email'] as String?,
  passwordExpiresInDays: (json['passwordExpiresInDays'] as num?)?.toInt(),
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'name': instance.name,
  'avatarFilename': instance.avatarFilename,
  'email': instance.email,
  'passwordExpiresInDays': instance.passwordExpiresInDays,
};
