// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$User {

 String get id; String get displayName; String? get email; bool get hasPasswordLogin; String? get avatarUrl; String? get bio; String get timezone; Map<String, dynamic>? get preferredGamingHours; String? get steamId; String? get appleId; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCopyWith<User> get copyWith => _$UserCopyWithImpl<User>(this as User, _$identity);

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is User&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.hasPasswordLogin, hasPasswordLogin) || other.hasPasswordLogin == hasPasswordLogin)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&const DeepCollectionEquality().equals(other.preferredGamingHours, preferredGamingHours)&&(identical(other.steamId, steamId) || other.steamId == steamId)&&(identical(other.appleId, appleId) || other.appleId == appleId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,email,hasPasswordLogin,avatarUrl,bio,timezone,const DeepCollectionEquality().hash(preferredGamingHours),steamId,appleId,createdAt,updatedAt);

@override
String toString() {
  return 'User(id: $id, displayName: $displayName, email: $email, hasPasswordLogin: $hasPasswordLogin, avatarUrl: $avatarUrl, bio: $bio, timezone: $timezone, preferredGamingHours: $preferredGamingHours, steamId: $steamId, appleId: $appleId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $UserCopyWith<$Res>  {
  factory $UserCopyWith(User value, $Res Function(User) _then) = _$UserCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String? email, bool hasPasswordLogin, String? avatarUrl, String? bio, String timezone, Map<String, dynamic>? preferredGamingHours, String? steamId, String? appleId, DateTime? createdAt, DateTime? updatedAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? email = freezed,Object? hasPasswordLogin = null,Object? avatarUrl = freezed,Object? bio = freezed,Object? timezone = null,Object? preferredGamingHours = freezed,Object? steamId = freezed,Object? appleId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,hasPasswordLogin: null == hasPasswordLogin ? _self.hasPasswordLogin : hasPasswordLogin // ignore: cast_nullable_to_non_nullable
as bool,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,preferredGamingHours: freezed == preferredGamingHours ? _self.preferredGamingHours : preferredGamingHours // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,steamId: freezed == steamId ? _self.steamId : steamId // ignore: cast_nullable_to_non_nullable
as String?,appleId: freezed == appleId ? _self.appleId : appleId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String? email,  bool hasPasswordLogin,  String? avatarUrl,  String? bio,  String timezone,  Map<String, dynamic>? preferredGamingHours,  String? steamId,  String? appleId,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.id,_that.displayName,_that.email,_that.hasPasswordLogin,_that.avatarUrl,_that.bio,_that.timezone,_that.preferredGamingHours,_that.steamId,_that.appleId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String? email,  bool hasPasswordLogin,  String? avatarUrl,  String? bio,  String timezone,  Map<String, dynamic>? preferredGamingHours,  String? steamId,  String? appleId,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _User():
return $default(_that.id,_that.displayName,_that.email,_that.hasPasswordLogin,_that.avatarUrl,_that.bio,_that.timezone,_that.preferredGamingHours,_that.steamId,_that.appleId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String? email,  bool hasPasswordLogin,  String? avatarUrl,  String? bio,  String timezone,  Map<String, dynamic>? preferredGamingHours,  String? steamId,  String? appleId,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.id,_that.displayName,_that.email,_that.hasPasswordLogin,_that.avatarUrl,_that.bio,_that.timezone,_that.preferredGamingHours,_that.steamId,_that.appleId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _User implements User {
  const _User({required this.id, required this.displayName, this.email, this.hasPasswordLogin = false, this.avatarUrl, this.bio, required this.timezone, final  Map<String, dynamic>? preferredGamingHours, this.steamId, this.appleId, this.createdAt, this.updatedAt}): _preferredGamingHours = preferredGamingHours;
  factory _User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

@override final  String id;
@override final  String displayName;
@override final  String? email;
@override@JsonKey() final  bool hasPasswordLogin;
@override final  String? avatarUrl;
@override final  String? bio;
@override final  String timezone;
 final  Map<String, dynamic>? _preferredGamingHours;
@override Map<String, dynamic>? get preferredGamingHours {
  final value = _preferredGamingHours;
  if (value == null) return null;
  if (_preferredGamingHours is EqualUnmodifiableMapView) return _preferredGamingHours;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? steamId;
@override final  String? appleId;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _User&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.hasPasswordLogin, hasPasswordLogin) || other.hasPasswordLogin == hasPasswordLogin)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&const DeepCollectionEquality().equals(other._preferredGamingHours, _preferredGamingHours)&&(identical(other.steamId, steamId) || other.steamId == steamId)&&(identical(other.appleId, appleId) || other.appleId == appleId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,email,hasPasswordLogin,avatarUrl,bio,timezone,const DeepCollectionEquality().hash(_preferredGamingHours),steamId,appleId,createdAt,updatedAt);

@override
String toString() {
  return 'User(id: $id, displayName: $displayName, email: $email, hasPasswordLogin: $hasPasswordLogin, avatarUrl: $avatarUrl, bio: $bio, timezone: $timezone, preferredGamingHours: $preferredGamingHours, steamId: $steamId, appleId: $appleId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$UserCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$UserCopyWith(_User value, $Res Function(_User) _then) = __$UserCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String? email, bool hasPasswordLogin, String? avatarUrl, String? bio, String timezone, Map<String, dynamic>? preferredGamingHours, String? steamId, String? appleId, DateTime? createdAt, DateTime? updatedAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? email = freezed,Object? hasPasswordLogin = null,Object? avatarUrl = freezed,Object? bio = freezed,Object? timezone = null,Object? preferredGamingHours = freezed,Object? steamId = freezed,Object? appleId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_User(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,hasPasswordLogin: null == hasPasswordLogin ? _self.hasPasswordLogin : hasPasswordLogin // ignore: cast_nullable_to_non_nullable
as bool,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,preferredGamingHours: freezed == preferredGamingHours ? _self._preferredGamingHours : preferredGamingHours // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,steamId: freezed == steamId ? _self.steamId : steamId // ignore: cast_nullable_to_non_nullable
as String?,appleId: freezed == appleId ? _self.appleId : appleId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
