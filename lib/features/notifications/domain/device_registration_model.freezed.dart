// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_registration_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeviceRegistration {

 String get id; String get platform; String get token; String? get deviceLabel; DateTime? get lastSeenAt;
/// Create a copy of DeviceRegistration
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceRegistrationCopyWith<DeviceRegistration> get copyWith => _$DeviceRegistrationCopyWithImpl<DeviceRegistration>(this as DeviceRegistration, _$identity);

  /// Serializes this DeviceRegistration to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceRegistration&&(identical(other.id, id) || other.id == id)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.token, token) || other.token == token)&&(identical(other.deviceLabel, deviceLabel) || other.deviceLabel == deviceLabel)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,platform,token,deviceLabel,lastSeenAt);

@override
String toString() {
  return 'DeviceRegistration(id: $id, platform: $platform, token: $token, deviceLabel: $deviceLabel, lastSeenAt: $lastSeenAt)';
}


}

/// @nodoc
abstract mixin class $DeviceRegistrationCopyWith<$Res>  {
  factory $DeviceRegistrationCopyWith(DeviceRegistration value, $Res Function(DeviceRegistration) _then) = _$DeviceRegistrationCopyWithImpl;
@useResult
$Res call({
 String id, String platform, String token, String? deviceLabel, DateTime? lastSeenAt
});




}
/// @nodoc
class _$DeviceRegistrationCopyWithImpl<$Res>
    implements $DeviceRegistrationCopyWith<$Res> {
  _$DeviceRegistrationCopyWithImpl(this._self, this._then);

  final DeviceRegistration _self;
  final $Res Function(DeviceRegistration) _then;

/// Create a copy of DeviceRegistration
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? platform = null,Object? token = null,Object? deviceLabel = freezed,Object? lastSeenAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,deviceLabel: freezed == deviceLabel ? _self.deviceLabel : deviceLabel // ignore: cast_nullable_to_non_nullable
as String?,lastSeenAt: freezed == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceRegistration].
extension DeviceRegistrationPatterns on DeviceRegistration {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceRegistration value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceRegistration() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceRegistration value)  $default,){
final _that = this;
switch (_that) {
case _DeviceRegistration():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceRegistration value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceRegistration() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String platform,  String token,  String? deviceLabel,  DateTime? lastSeenAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceRegistration() when $default != null:
return $default(_that.id,_that.platform,_that.token,_that.deviceLabel,_that.lastSeenAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String platform,  String token,  String? deviceLabel,  DateTime? lastSeenAt)  $default,) {final _that = this;
switch (_that) {
case _DeviceRegistration():
return $default(_that.id,_that.platform,_that.token,_that.deviceLabel,_that.lastSeenAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String platform,  String token,  String? deviceLabel,  DateTime? lastSeenAt)?  $default,) {final _that = this;
switch (_that) {
case _DeviceRegistration() when $default != null:
return $default(_that.id,_that.platform,_that.token,_that.deviceLabel,_that.lastSeenAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceRegistration implements DeviceRegistration {
  const _DeviceRegistration({required this.id, required this.platform, required this.token, this.deviceLabel, this.lastSeenAt});
  factory _DeviceRegistration.fromJson(Map<String, dynamic> json) => _$DeviceRegistrationFromJson(json);

@override final  String id;
@override final  String platform;
@override final  String token;
@override final  String? deviceLabel;
@override final  DateTime? lastSeenAt;

/// Create a copy of DeviceRegistration
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceRegistrationCopyWith<_DeviceRegistration> get copyWith => __$DeviceRegistrationCopyWithImpl<_DeviceRegistration>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceRegistrationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceRegistration&&(identical(other.id, id) || other.id == id)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.token, token) || other.token == token)&&(identical(other.deviceLabel, deviceLabel) || other.deviceLabel == deviceLabel)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,platform,token,deviceLabel,lastSeenAt);

@override
String toString() {
  return 'DeviceRegistration(id: $id, platform: $platform, token: $token, deviceLabel: $deviceLabel, lastSeenAt: $lastSeenAt)';
}


}

/// @nodoc
abstract mixin class _$DeviceRegistrationCopyWith<$Res> implements $DeviceRegistrationCopyWith<$Res> {
  factory _$DeviceRegistrationCopyWith(_DeviceRegistration value, $Res Function(_DeviceRegistration) _then) = __$DeviceRegistrationCopyWithImpl;
@override @useResult
$Res call({
 String id, String platform, String token, String? deviceLabel, DateTime? lastSeenAt
});




}
/// @nodoc
class __$DeviceRegistrationCopyWithImpl<$Res>
    implements _$DeviceRegistrationCopyWith<$Res> {
  __$DeviceRegistrationCopyWithImpl(this._self, this._then);

  final _DeviceRegistration _self;
  final $Res Function(_DeviceRegistration) _then;

/// Create a copy of DeviceRegistration
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? platform = null,Object? token = null,Object? deviceLabel = freezed,Object? lastSeenAt = freezed,}) {
  return _then(_DeviceRegistration(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,deviceLabel: freezed == deviceLabel ? _self.deviceLabel : deviceLabel // ignore: cast_nullable_to_non_nullable
as String?,lastSeenAt: freezed == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
