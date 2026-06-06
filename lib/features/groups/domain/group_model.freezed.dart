// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Group {

 String get id; String get name; String? get description; String get inviteCode; bool get isDiscoverable; String get joinMode; String? get avatarUrl; String get createdBy; int get memberCount; bool get hasPendingJoinRequest; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupCopyWith<Group> get copyWith => _$GroupCopyWithImpl<Group>(this as Group, _$identity);

  /// Serializes this Group to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Group&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode)&&(identical(other.isDiscoverable, isDiscoverable) || other.isDiscoverable == isDiscoverable)&&(identical(other.joinMode, joinMode) || other.joinMode == joinMode)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&(identical(other.hasPendingJoinRequest, hasPendingJoinRequest) || other.hasPendingJoinRequest == hasPendingJoinRequest)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,inviteCode,isDiscoverable,joinMode,avatarUrl,createdBy,memberCount,hasPendingJoinRequest,createdAt,updatedAt);

@override
String toString() {
  return 'Group(id: $id, name: $name, description: $description, inviteCode: $inviteCode, isDiscoverable: $isDiscoverable, joinMode: $joinMode, avatarUrl: $avatarUrl, createdBy: $createdBy, memberCount: $memberCount, hasPendingJoinRequest: $hasPendingJoinRequest, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $GroupCopyWith<$Res>  {
  factory $GroupCopyWith(Group value, $Res Function(Group) _then) = _$GroupCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description, String inviteCode, bool isDiscoverable, String joinMode, String? avatarUrl, String createdBy, int memberCount, bool hasPendingJoinRequest, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$GroupCopyWithImpl<$Res>
    implements $GroupCopyWith<$Res> {
  _$GroupCopyWithImpl(this._self, this._then);

  final Group _self;
  final $Res Function(Group) _then;

/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? inviteCode = null,Object? isDiscoverable = null,Object? joinMode = null,Object? avatarUrl = freezed,Object? createdBy = null,Object? memberCount = null,Object? hasPendingJoinRequest = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,inviteCode: null == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String,isDiscoverable: null == isDiscoverable ? _self.isDiscoverable : isDiscoverable // ignore: cast_nullable_to_non_nullable
as bool,joinMode: null == joinMode ? _self.joinMode : joinMode // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,hasPendingJoinRequest: null == hasPendingJoinRequest ? _self.hasPendingJoinRequest : hasPendingJoinRequest // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Group].
extension GroupPatterns on Group {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Group value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Group() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Group value)  $default,){
final _that = this;
switch (_that) {
case _Group():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Group value)?  $default,){
final _that = this;
switch (_that) {
case _Group() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String inviteCode,  bool isDiscoverable,  String joinMode,  String? avatarUrl,  String createdBy,  int memberCount,  bool hasPendingJoinRequest,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Group() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.inviteCode,_that.isDiscoverable,_that.joinMode,_that.avatarUrl,_that.createdBy,_that.memberCount,_that.hasPendingJoinRequest,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String inviteCode,  bool isDiscoverable,  String joinMode,  String? avatarUrl,  String createdBy,  int memberCount,  bool hasPendingJoinRequest,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Group():
return $default(_that.id,_that.name,_that.description,_that.inviteCode,_that.isDiscoverable,_that.joinMode,_that.avatarUrl,_that.createdBy,_that.memberCount,_that.hasPendingJoinRequest,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description,  String inviteCode,  bool isDiscoverable,  String joinMode,  String? avatarUrl,  String createdBy,  int memberCount,  bool hasPendingJoinRequest,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Group() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.inviteCode,_that.isDiscoverable,_that.joinMode,_that.avatarUrl,_that.createdBy,_that.memberCount,_that.hasPendingJoinRequest,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Group implements Group {
  const _Group({required this.id, required this.name, this.description, required this.inviteCode, required this.isDiscoverable, required this.joinMode, this.avatarUrl, required this.createdBy, required this.memberCount, this.hasPendingJoinRequest = false, this.createdAt, this.updatedAt});
  factory _Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? description;
@override final  String inviteCode;
@override final  bool isDiscoverable;
@override final  String joinMode;
@override final  String? avatarUrl;
@override final  String createdBy;
@override final  int memberCount;
@override@JsonKey() final  bool hasPendingJoinRequest;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupCopyWith<_Group> get copyWith => __$GroupCopyWithImpl<_Group>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Group&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode)&&(identical(other.isDiscoverable, isDiscoverable) || other.isDiscoverable == isDiscoverable)&&(identical(other.joinMode, joinMode) || other.joinMode == joinMode)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&(identical(other.hasPendingJoinRequest, hasPendingJoinRequest) || other.hasPendingJoinRequest == hasPendingJoinRequest)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,inviteCode,isDiscoverable,joinMode,avatarUrl,createdBy,memberCount,hasPendingJoinRequest,createdAt,updatedAt);

@override
String toString() {
  return 'Group(id: $id, name: $name, description: $description, inviteCode: $inviteCode, isDiscoverable: $isDiscoverable, joinMode: $joinMode, avatarUrl: $avatarUrl, createdBy: $createdBy, memberCount: $memberCount, hasPendingJoinRequest: $hasPendingJoinRequest, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$GroupCopyWith<$Res> implements $GroupCopyWith<$Res> {
  factory _$GroupCopyWith(_Group value, $Res Function(_Group) _then) = __$GroupCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description, String inviteCode, bool isDiscoverable, String joinMode, String? avatarUrl, String createdBy, int memberCount, bool hasPendingJoinRequest, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$GroupCopyWithImpl<$Res>
    implements _$GroupCopyWith<$Res> {
  __$GroupCopyWithImpl(this._self, this._then);

  final _Group _self;
  final $Res Function(_Group) _then;

/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? inviteCode = null,Object? isDiscoverable = null,Object? joinMode = null,Object? avatarUrl = freezed,Object? createdBy = null,Object? memberCount = null,Object? hasPendingJoinRequest = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Group(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,inviteCode: null == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String,isDiscoverable: null == isDiscoverable ? _self.isDiscoverable : isDiscoverable // ignore: cast_nullable_to_non_nullable
as bool,joinMode: null == joinMode ? _self.joinMode : joinMode // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,hasPendingJoinRequest: null == hasPendingJoinRequest ? _self.hasPendingJoinRequest : hasPendingJoinRequest // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
