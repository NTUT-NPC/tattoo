// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'i_school_plus.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ISchoolPlusStudent {

 String? get id; String? get name;
/// Create a copy of ISchoolPlusStudent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ISchoolPlusStudentCopyWith<ISchoolPlusStudent> get copyWith => _$ISchoolPlusStudentCopyWithImpl<ISchoolPlusStudent>(this as ISchoolPlusStudent, _$identity);

  /// Serializes this ISchoolPlusStudent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ISchoolPlusStudent&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'ISchoolPlusStudent(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $ISchoolPlusStudentCopyWith<$Res>  {
  factory $ISchoolPlusStudentCopyWith(ISchoolPlusStudent value, $Res Function(ISchoolPlusStudent) _then) = _$ISchoolPlusStudentCopyWithImpl;
@useResult
$Res call({
 String? id, String? name
});




}
/// @nodoc
class _$ISchoolPlusStudentCopyWithImpl<$Res>
    implements $ISchoolPlusStudentCopyWith<$Res> {
  _$ISchoolPlusStudentCopyWithImpl(this._self, this._then);

  final ISchoolPlusStudent _self;
  final $Res Function(ISchoolPlusStudent) _then;

/// Create a copy of ISchoolPlusStudent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ISchoolPlusStudent].
extension ISchoolPlusStudentPatterns on ISchoolPlusStudent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ISchoolPlusStudent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ISchoolPlusStudent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ISchoolPlusStudent value)  $default,){
final _that = this;
switch (_that) {
case _ISchoolPlusStudent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ISchoolPlusStudent value)?  $default,){
final _that = this;
switch (_that) {
case _ISchoolPlusStudent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ISchoolPlusStudent() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String? name)  $default,) {final _that = this;
switch (_that) {
case _ISchoolPlusStudent():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String? name)?  $default,) {final _that = this;
switch (_that) {
case _ISchoolPlusStudent() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ISchoolPlusStudent implements ISchoolPlusStudent {
  const _ISchoolPlusStudent({this.id, this.name});
  factory _ISchoolPlusStudent.fromJson(Map<String, dynamic> json) => _$ISchoolPlusStudentFromJson(json);

@override final  String? id;
@override final  String? name;

/// Create a copy of ISchoolPlusStudent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ISchoolPlusStudentCopyWith<_ISchoolPlusStudent> get copyWith => __$ISchoolPlusStudentCopyWithImpl<_ISchoolPlusStudent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ISchoolPlusStudentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ISchoolPlusStudent&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'ISchoolPlusStudent(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$ISchoolPlusStudentCopyWith<$Res> implements $ISchoolPlusStudentCopyWith<$Res> {
  factory _$ISchoolPlusStudentCopyWith(_ISchoolPlusStudent value, $Res Function(_ISchoolPlusStudent) _then) = __$ISchoolPlusStudentCopyWithImpl;
@override @useResult
$Res call({
 String? id, String? name
});




}
/// @nodoc
class __$ISchoolPlusStudentCopyWithImpl<$Res>
    implements _$ISchoolPlusStudentCopyWith<$Res> {
  __$ISchoolPlusStudentCopyWithImpl(this._self, this._then);

  final _ISchoolPlusStudent _self;
  final $Res Function(_ISchoolPlusStudent) _then;

/// Create a copy of ISchoolPlusStudent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = freezed,}) {
  return _then(_ISchoolPlusStudent(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ISchoolPlusMaterialRef {

 String? get title; String? get href;
/// Create a copy of ISchoolPlusMaterialRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ISchoolPlusMaterialRefCopyWith<ISchoolPlusMaterialRef> get copyWith => _$ISchoolPlusMaterialRefCopyWithImpl<ISchoolPlusMaterialRef>(this as ISchoolPlusMaterialRef, _$identity);

  /// Serializes this ISchoolPlusMaterialRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ISchoolPlusMaterialRef&&(identical(other.title, title) || other.title == title)&&(identical(other.href, href) || other.href == href));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,href);

@override
String toString() {
  return 'ISchoolPlusMaterialRef(title: $title, href: $href)';
}


}

/// @nodoc
abstract mixin class $ISchoolPlusMaterialRefCopyWith<$Res>  {
  factory $ISchoolPlusMaterialRefCopyWith(ISchoolPlusMaterialRef value, $Res Function(ISchoolPlusMaterialRef) _then) = _$ISchoolPlusMaterialRefCopyWithImpl;
@useResult
$Res call({
 String? title, String? href
});




}
/// @nodoc
class _$ISchoolPlusMaterialRefCopyWithImpl<$Res>
    implements $ISchoolPlusMaterialRefCopyWith<$Res> {
  _$ISchoolPlusMaterialRefCopyWithImpl(this._self, this._then);

  final ISchoolPlusMaterialRef _self;
  final $Res Function(ISchoolPlusMaterialRef) _then;

/// Create a copy of ISchoolPlusMaterialRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? href = freezed,}) {
  return _then(_self.copyWith(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,href: freezed == href ? _self.href : href // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ISchoolPlusMaterialRef].
extension ISchoolPlusMaterialRefPatterns on ISchoolPlusMaterialRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ISchoolPlusMaterialRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ISchoolPlusMaterialRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ISchoolPlusMaterialRef value)  $default,){
final _that = this;
switch (_that) {
case _ISchoolPlusMaterialRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ISchoolPlusMaterialRef value)?  $default,){
final _that = this;
switch (_that) {
case _ISchoolPlusMaterialRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  String? href)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ISchoolPlusMaterialRef() when $default != null:
return $default(_that.title,_that.href);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  String? href)  $default,) {final _that = this;
switch (_that) {
case _ISchoolPlusMaterialRef():
return $default(_that.title,_that.href);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  String? href)?  $default,) {final _that = this;
switch (_that) {
case _ISchoolPlusMaterialRef() when $default != null:
return $default(_that.title,_that.href);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ISchoolPlusMaterialRef implements ISchoolPlusMaterialRef {
  const _ISchoolPlusMaterialRef({this.title, this.href});
  factory _ISchoolPlusMaterialRef.fromJson(Map<String, dynamic> json) => _$ISchoolPlusMaterialRefFromJson(json);

@override final  String? title;
@override final  String? href;

/// Create a copy of ISchoolPlusMaterialRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ISchoolPlusMaterialRefCopyWith<_ISchoolPlusMaterialRef> get copyWith => __$ISchoolPlusMaterialRefCopyWithImpl<_ISchoolPlusMaterialRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ISchoolPlusMaterialRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ISchoolPlusMaterialRef&&(identical(other.title, title) || other.title == title)&&(identical(other.href, href) || other.href == href));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,href);

@override
String toString() {
  return 'ISchoolPlusMaterialRef(title: $title, href: $href)';
}


}

/// @nodoc
abstract mixin class _$ISchoolPlusMaterialRefCopyWith<$Res> implements $ISchoolPlusMaterialRefCopyWith<$Res> {
  factory _$ISchoolPlusMaterialRefCopyWith(_ISchoolPlusMaterialRef value, $Res Function(_ISchoolPlusMaterialRef) _then) = __$ISchoolPlusMaterialRefCopyWithImpl;
@override @useResult
$Res call({
 String? title, String? href
});




}
/// @nodoc
class __$ISchoolPlusMaterialRefCopyWithImpl<$Res>
    implements _$ISchoolPlusMaterialRefCopyWith<$Res> {
  __$ISchoolPlusMaterialRefCopyWithImpl(this._self, this._then);

  final _ISchoolPlusMaterialRef _self;
  final $Res Function(_ISchoolPlusMaterialRef) _then;

/// Create a copy of ISchoolPlusMaterialRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? href = freezed,}) {
  return _then(_ISchoolPlusMaterialRef(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,href: freezed == href ? _self.href : href // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ISchoolPlusMaterial {

 Uri get downloadUrl; String? get referer;
/// Create a copy of ISchoolPlusMaterial
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ISchoolPlusMaterialCopyWith<ISchoolPlusMaterial> get copyWith => _$ISchoolPlusMaterialCopyWithImpl<ISchoolPlusMaterial>(this as ISchoolPlusMaterial, _$identity);

  /// Serializes this ISchoolPlusMaterial to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ISchoolPlusMaterial&&(identical(other.downloadUrl, downloadUrl) || other.downloadUrl == downloadUrl)&&(identical(other.referer, referer) || other.referer == referer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,downloadUrl,referer);

@override
String toString() {
  return 'ISchoolPlusMaterial(downloadUrl: $downloadUrl, referer: $referer)';
}


}

/// @nodoc
abstract mixin class $ISchoolPlusMaterialCopyWith<$Res>  {
  factory $ISchoolPlusMaterialCopyWith(ISchoolPlusMaterial value, $Res Function(ISchoolPlusMaterial) _then) = _$ISchoolPlusMaterialCopyWithImpl;
@useResult
$Res call({
 Uri downloadUrl, String? referer
});




}
/// @nodoc
class _$ISchoolPlusMaterialCopyWithImpl<$Res>
    implements $ISchoolPlusMaterialCopyWith<$Res> {
  _$ISchoolPlusMaterialCopyWithImpl(this._self, this._then);

  final ISchoolPlusMaterial _self;
  final $Res Function(ISchoolPlusMaterial) _then;

/// Create a copy of ISchoolPlusMaterial
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? downloadUrl = null,Object? referer = freezed,}) {
  return _then(_self.copyWith(
downloadUrl: null == downloadUrl ? _self.downloadUrl : downloadUrl // ignore: cast_nullable_to_non_nullable
as Uri,referer: freezed == referer ? _self.referer : referer // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ISchoolPlusMaterial].
extension ISchoolPlusMaterialPatterns on ISchoolPlusMaterial {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ISchoolPlusMaterial value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ISchoolPlusMaterial() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ISchoolPlusMaterial value)  $default,){
final _that = this;
switch (_that) {
case _ISchoolPlusMaterial():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ISchoolPlusMaterial value)?  $default,){
final _that = this;
switch (_that) {
case _ISchoolPlusMaterial() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Uri downloadUrl,  String? referer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ISchoolPlusMaterial() when $default != null:
return $default(_that.downloadUrl,_that.referer);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Uri downloadUrl,  String? referer)  $default,) {final _that = this;
switch (_that) {
case _ISchoolPlusMaterial():
return $default(_that.downloadUrl,_that.referer);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Uri downloadUrl,  String? referer)?  $default,) {final _that = this;
switch (_that) {
case _ISchoolPlusMaterial() when $default != null:
return $default(_that.downloadUrl,_that.referer);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ISchoolPlusMaterial implements ISchoolPlusMaterial {
  const _ISchoolPlusMaterial({required this.downloadUrl, this.referer});
  factory _ISchoolPlusMaterial.fromJson(Map<String, dynamic> json) => _$ISchoolPlusMaterialFromJson(json);

@override final  Uri downloadUrl;
@override final  String? referer;

/// Create a copy of ISchoolPlusMaterial
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ISchoolPlusMaterialCopyWith<_ISchoolPlusMaterial> get copyWith => __$ISchoolPlusMaterialCopyWithImpl<_ISchoolPlusMaterial>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ISchoolPlusMaterialToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ISchoolPlusMaterial&&(identical(other.downloadUrl, downloadUrl) || other.downloadUrl == downloadUrl)&&(identical(other.referer, referer) || other.referer == referer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,downloadUrl,referer);

@override
String toString() {
  return 'ISchoolPlusMaterial(downloadUrl: $downloadUrl, referer: $referer)';
}


}

/// @nodoc
abstract mixin class _$ISchoolPlusMaterialCopyWith<$Res> implements $ISchoolPlusMaterialCopyWith<$Res> {
  factory _$ISchoolPlusMaterialCopyWith(_ISchoolPlusMaterial value, $Res Function(_ISchoolPlusMaterial) _then) = __$ISchoolPlusMaterialCopyWithImpl;
@override @useResult
$Res call({
 Uri downloadUrl, String? referer
});




}
/// @nodoc
class __$ISchoolPlusMaterialCopyWithImpl<$Res>
    implements _$ISchoolPlusMaterialCopyWith<$Res> {
  __$ISchoolPlusMaterialCopyWithImpl(this._self, this._then);

  final _ISchoolPlusMaterial _self;
  final $Res Function(_ISchoolPlusMaterial) _then;

/// Create a copy of ISchoolPlusMaterial
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? downloadUrl = null,Object? referer = freezed,}) {
  return _then(_ISchoolPlusMaterial(
downloadUrl: null == downloadUrl ? _self.downloadUrl : downloadUrl // ignore: cast_nullable_to_non_nullable
as Uri,referer: freezed == referer ? _self.referer : referer // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
