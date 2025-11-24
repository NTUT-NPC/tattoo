// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$User {

/// User's display name from NTUT Portal (givenName).
 String? get name;/// Filename of the user's profile photo (e.g., "111360109_temp1714460935341.jpeg").
 String? get avatarFilename;/// User's NTUT email address (e.g., "t111360109@ntut.edu.tw").
 String? get email;/// Number of days until the password expires.
///
/// When non-null, indicates the user should change their password soon.
/// The value corresponds to the `passwordExpiredRemind` field from the login API.
/// Null if there is no expiration warning.
 int? get passwordExpiresInDays;
/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCopyWith<User> get copyWith => _$UserCopyWithImpl<User>(this as User, _$identity);

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is User&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarFilename, avatarFilename) || other.avatarFilename == avatarFilename)&&(identical(other.email, email) || other.email == email)&&(identical(other.passwordExpiresInDays, passwordExpiresInDays) || other.passwordExpiresInDays == passwordExpiresInDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,avatarFilename,email,passwordExpiresInDays);

@override
String toString() {
  return 'User(name: $name, avatarFilename: $avatarFilename, email: $email, passwordExpiresInDays: $passwordExpiresInDays)';
}


}

/// @nodoc
abstract mixin class $UserCopyWith<$Res>  {
  factory $UserCopyWith(User value, $Res Function(User) _then) = _$UserCopyWithImpl;
@useResult
$Res call({
 String? name, String? avatarFilename, String? email, int? passwordExpiresInDays
});




}
/// @nodoc
class _$UserCopyWithImpl<$Res>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._self, this._then);

  final User _self;
  final $Res Function(User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? avatarFilename = freezed,Object? email = freezed,Object? passwordExpiresInDays = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,avatarFilename: freezed == avatarFilename ? _self.avatarFilename : avatarFilename // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,passwordExpiresInDays: freezed == passwordExpiresInDays ? _self.passwordExpiresInDays : passwordExpiresInDays // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [User].
extension UserPatterns on User {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _User value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _User value)  $default,){
final _that = this;
switch (_that) {
case _User():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _User value)?  $default,){
final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  String? avatarFilename,  String? email,  int? passwordExpiresInDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.name,_that.avatarFilename,_that.email,_that.passwordExpiresInDays);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  String? avatarFilename,  String? email,  int? passwordExpiresInDays)  $default,) {final _that = this;
switch (_that) {
case _User():
return $default(_that.name,_that.avatarFilename,_that.email,_that.passwordExpiresInDays);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  String? avatarFilename,  String? email,  int? passwordExpiresInDays)?  $default,) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.name,_that.avatarFilename,_that.email,_that.passwordExpiresInDays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _User implements User {
  const _User({this.name, this.avatarFilename, this.email, this.passwordExpiresInDays});
  factory _User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

/// User's display name from NTUT Portal (givenName).
@override final  String? name;
/// Filename of the user's profile photo (e.g., "111360109_temp1714460935341.jpeg").
@override final  String? avatarFilename;
/// User's NTUT email address (e.g., "t111360109@ntut.edu.tw").
@override final  String? email;
/// Number of days until the password expires.
///
/// When non-null, indicates the user should change their password soon.
/// The value corresponds to the `passwordExpiredRemind` field from the login API.
/// Null if there is no expiration warning.
@override final  int? passwordExpiresInDays;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCopyWith<_User> get copyWith => __$UserCopyWithImpl<_User>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _User&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarFilename, avatarFilename) || other.avatarFilename == avatarFilename)&&(identical(other.email, email) || other.email == email)&&(identical(other.passwordExpiresInDays, passwordExpiresInDays) || other.passwordExpiresInDays == passwordExpiresInDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,avatarFilename,email,passwordExpiresInDays);

@override
String toString() {
  return 'User(name: $name, avatarFilename: $avatarFilename, email: $email, passwordExpiresInDays: $passwordExpiresInDays)';
}


}

/// @nodoc
abstract mixin class _$UserCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$UserCopyWith(_User value, $Res Function(_User) _then) = __$UserCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? avatarFilename, String? email, int? passwordExpiresInDays
});




}
/// @nodoc
class __$UserCopyWithImpl<$Res>
    implements _$UserCopyWith<$Res> {
  __$UserCopyWithImpl(this._self, this._then);

  final _User _self;
  final $Res Function(_User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? avatarFilename = freezed,Object? email = freezed,Object? passwordExpiresInDays = freezed,}) {
  return _then(_User(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,avatarFilename: freezed == avatarFilename ? _self.avatarFilename : avatarFilename // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,passwordExpiresInDays: freezed == passwordExpiresInDays ? _self.passwordExpiresInDays : passwordExpiresInDays // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
