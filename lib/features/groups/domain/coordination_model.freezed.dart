// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coordination_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScheduledReadyWindow {

 String get id; String get groupId; String get userId; String get displayName; DateTime get startsAt; DateTime get endsAt; String get source; DateTime get createdAt; DateTime? get updatedAt;
/// Create a copy of ScheduledReadyWindow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduledReadyWindowCopyWith<ScheduledReadyWindow> get copyWith => _$ScheduledReadyWindowCopyWithImpl<ScheduledReadyWindow>(this as ScheduledReadyWindow, _$identity);

  /// Serializes this ScheduledReadyWindow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduledReadyWindow&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.source, source) || other.source == source)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,groupId,userId,displayName,startsAt,endsAt,source,createdAt,updatedAt);

@override
String toString() {
  return 'ScheduledReadyWindow(id: $id, groupId: $groupId, userId: $userId, displayName: $displayName, startsAt: $startsAt, endsAt: $endsAt, source: $source, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ScheduledReadyWindowCopyWith<$Res>  {
  factory $ScheduledReadyWindowCopyWith(ScheduledReadyWindow value, $Res Function(ScheduledReadyWindow) _then) = _$ScheduledReadyWindowCopyWithImpl;
@useResult
$Res call({
 String id, String groupId, String userId, String displayName, DateTime startsAt, DateTime endsAt, String source, DateTime createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$ScheduledReadyWindowCopyWithImpl<$Res>
    implements $ScheduledReadyWindowCopyWith<$Res> {
  _$ScheduledReadyWindowCopyWithImpl(this._self, this._then);

  final ScheduledReadyWindow _self;
  final $Res Function(ScheduledReadyWindow) _then;

/// Create a copy of ScheduledReadyWindow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? userId = null,Object? displayName = null,Object? startsAt = null,Object? endsAt = null,Object? source = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScheduledReadyWindow].
extension ScheduledReadyWindowPatterns on ScheduledReadyWindow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduledReadyWindow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduledReadyWindow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduledReadyWindow value)  $default,){
final _that = this;
switch (_that) {
case _ScheduledReadyWindow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduledReadyWindow value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduledReadyWindow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String groupId,  String userId,  String displayName,  DateTime startsAt,  DateTime endsAt,  String source,  DateTime createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduledReadyWindow() when $default != null:
return $default(_that.id,_that.groupId,_that.userId,_that.displayName,_that.startsAt,_that.endsAt,_that.source,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String groupId,  String userId,  String displayName,  DateTime startsAt,  DateTime endsAt,  String source,  DateTime createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ScheduledReadyWindow():
return $default(_that.id,_that.groupId,_that.userId,_that.displayName,_that.startsAt,_that.endsAt,_that.source,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String groupId,  String userId,  String displayName,  DateTime startsAt,  DateTime endsAt,  String source,  DateTime createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ScheduledReadyWindow() when $default != null:
return $default(_that.id,_that.groupId,_that.userId,_that.displayName,_that.startsAt,_that.endsAt,_that.source,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScheduledReadyWindow implements ScheduledReadyWindow {
  const _ScheduledReadyWindow({required this.id, required this.groupId, required this.userId, required this.displayName, required this.startsAt, required this.endsAt, required this.source, required this.createdAt, this.updatedAt});
  factory _ScheduledReadyWindow.fromJson(Map<String, dynamic> json) => _$ScheduledReadyWindowFromJson(json);

@override final  String id;
@override final  String groupId;
@override final  String userId;
@override final  String displayName;
@override final  DateTime startsAt;
@override final  DateTime endsAt;
@override final  String source;
@override final  DateTime createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of ScheduledReadyWindow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduledReadyWindowCopyWith<_ScheduledReadyWindow> get copyWith => __$ScheduledReadyWindowCopyWithImpl<_ScheduledReadyWindow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScheduledReadyWindowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduledReadyWindow&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.source, source) || other.source == source)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,groupId,userId,displayName,startsAt,endsAt,source,createdAt,updatedAt);

@override
String toString() {
  return 'ScheduledReadyWindow(id: $id, groupId: $groupId, userId: $userId, displayName: $displayName, startsAt: $startsAt, endsAt: $endsAt, source: $source, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ScheduledReadyWindowCopyWith<$Res> implements $ScheduledReadyWindowCopyWith<$Res> {
  factory _$ScheduledReadyWindowCopyWith(_ScheduledReadyWindow value, $Res Function(_ScheduledReadyWindow) _then) = __$ScheduledReadyWindowCopyWithImpl;
@override @useResult
$Res call({
 String id, String groupId, String userId, String displayName, DateTime startsAt, DateTime endsAt, String source, DateTime createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$ScheduledReadyWindowCopyWithImpl<$Res>
    implements _$ScheduledReadyWindowCopyWith<$Res> {
  __$ScheduledReadyWindowCopyWithImpl(this._self, this._then);

  final _ScheduledReadyWindow _self;
  final $Res Function(_ScheduledReadyWindow) _then;

/// Create a copy of ScheduledReadyWindow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? userId = null,Object? displayName = null,Object? startsAt = null,Object? endsAt = null,Object? source = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_ScheduledReadyWindow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$SessionRsvp {

 String get id; String get sessionId; String get userId; String get displayName; String get response; DateTime get updatedAt;
/// Create a copy of SessionRsvp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionRsvpCopyWith<SessionRsvp> get copyWith => _$SessionRsvpCopyWithImpl<SessionRsvp>(this as SessionRsvp, _$identity);

  /// Serializes this SessionRsvp to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionRsvp&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.response, response) || other.response == response)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,userId,displayName,response,updatedAt);

@override
String toString() {
  return 'SessionRsvp(id: $id, sessionId: $sessionId, userId: $userId, displayName: $displayName, response: $response, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SessionRsvpCopyWith<$Res>  {
  factory $SessionRsvpCopyWith(SessionRsvp value, $Res Function(SessionRsvp) _then) = _$SessionRsvpCopyWithImpl;
@useResult
$Res call({
 String id, String sessionId, String userId, String displayName, String response, DateTime updatedAt
});




}
/// @nodoc
class _$SessionRsvpCopyWithImpl<$Res>
    implements $SessionRsvpCopyWith<$Res> {
  _$SessionRsvpCopyWithImpl(this._self, this._then);

  final SessionRsvp _self;
  final $Res Function(SessionRsvp) _then;

/// Create a copy of SessionRsvp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? userId = null,Object? displayName = null,Object? response = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,response: null == response ? _self.response : response // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionRsvp].
extension SessionRsvpPatterns on SessionRsvp {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionRsvp value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionRsvp() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionRsvp value)  $default,){
final _that = this;
switch (_that) {
case _SessionRsvp():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionRsvp value)?  $default,){
final _that = this;
switch (_that) {
case _SessionRsvp() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sessionId,  String userId,  String displayName,  String response,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionRsvp() when $default != null:
return $default(_that.id,_that.sessionId,_that.userId,_that.displayName,_that.response,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sessionId,  String userId,  String displayName,  String response,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SessionRsvp():
return $default(_that.id,_that.sessionId,_that.userId,_that.displayName,_that.response,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sessionId,  String userId,  String displayName,  String response,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SessionRsvp() when $default != null:
return $default(_that.id,_that.sessionId,_that.userId,_that.displayName,_that.response,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionRsvp implements SessionRsvp {
  const _SessionRsvp({required this.id, required this.sessionId, required this.userId, required this.displayName, required this.response, required this.updatedAt});
  factory _SessionRsvp.fromJson(Map<String, dynamic> json) => _$SessionRsvpFromJson(json);

@override final  String id;
@override final  String sessionId;
@override final  String userId;
@override final  String displayName;
@override final  String response;
@override final  DateTime updatedAt;

/// Create a copy of SessionRsvp
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionRsvpCopyWith<_SessionRsvp> get copyWith => __$SessionRsvpCopyWithImpl<_SessionRsvp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionRsvpToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionRsvp&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.response, response) || other.response == response)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,userId,displayName,response,updatedAt);

@override
String toString() {
  return 'SessionRsvp(id: $id, sessionId: $sessionId, userId: $userId, displayName: $displayName, response: $response, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SessionRsvpCopyWith<$Res> implements $SessionRsvpCopyWith<$Res> {
  factory _$SessionRsvpCopyWith(_SessionRsvp value, $Res Function(_SessionRsvp) _then) = __$SessionRsvpCopyWithImpl;
@override @useResult
$Res call({
 String id, String sessionId, String userId, String displayName, String response, DateTime updatedAt
});




}
/// @nodoc
class __$SessionRsvpCopyWithImpl<$Res>
    implements _$SessionRsvpCopyWith<$Res> {
  __$SessionRsvpCopyWithImpl(this._self, this._then);

  final _SessionRsvp _self;
  final $Res Function(_SessionRsvp) _then;

/// Create a copy of SessionRsvp
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? userId = null,Object? displayName = null,Object? response = null,Object? updatedAt = null,}) {
  return _then(_SessionRsvp(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,response: null == response ? _self.response : response // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$GroupSession {

 String get id; String get groupId; String get proposedBy; String get proposedByDisplayName; String? get title; String? get game; DateTime get startsAt; String? get notes; String get status; DateTime get createdAt; DateTime? get updatedAt; List<SessionRsvp> get rsvps;
/// Create a copy of GroupSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupSessionCopyWith<GroupSession> get copyWith => _$GroupSessionCopyWithImpl<GroupSession>(this as GroupSession, _$identity);

  /// Serializes this GroupSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupSession&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.proposedBy, proposedBy) || other.proposedBy == proposedBy)&&(identical(other.proposedByDisplayName, proposedByDisplayName) || other.proposedByDisplayName == proposedByDisplayName)&&(identical(other.title, title) || other.title == title)&&(identical(other.game, game) || other.game == game)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.rsvps, rsvps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,groupId,proposedBy,proposedByDisplayName,title,game,startsAt,notes,status,createdAt,updatedAt,const DeepCollectionEquality().hash(rsvps));

@override
String toString() {
  return 'GroupSession(id: $id, groupId: $groupId, proposedBy: $proposedBy, proposedByDisplayName: $proposedByDisplayName, title: $title, game: $game, startsAt: $startsAt, notes: $notes, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, rsvps: $rsvps)';
}


}

/// @nodoc
abstract mixin class $GroupSessionCopyWith<$Res>  {
  factory $GroupSessionCopyWith(GroupSession value, $Res Function(GroupSession) _then) = _$GroupSessionCopyWithImpl;
@useResult
$Res call({
 String id, String groupId, String proposedBy, String proposedByDisplayName, String? title, String? game, DateTime startsAt, String? notes, String status, DateTime createdAt, DateTime? updatedAt, List<SessionRsvp> rsvps
});




}
/// @nodoc
class _$GroupSessionCopyWithImpl<$Res>
    implements $GroupSessionCopyWith<$Res> {
  _$GroupSessionCopyWithImpl(this._self, this._then);

  final GroupSession _self;
  final $Res Function(GroupSession) _then;

/// Create a copy of GroupSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? proposedBy = null,Object? proposedByDisplayName = null,Object? title = freezed,Object? game = freezed,Object? startsAt = null,Object? notes = freezed,Object? status = null,Object? createdAt = null,Object? updatedAt = freezed,Object? rsvps = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,proposedBy: null == proposedBy ? _self.proposedBy : proposedBy // ignore: cast_nullable_to_non_nullable
as String,proposedByDisplayName: null == proposedByDisplayName ? _self.proposedByDisplayName : proposedByDisplayName // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,game: freezed == game ? _self.game : game // ignore: cast_nullable_to_non_nullable
as String?,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rsvps: null == rsvps ? _self.rsvps : rsvps // ignore: cast_nullable_to_non_nullable
as List<SessionRsvp>,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupSession].
extension GroupSessionPatterns on GroupSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupSession value)  $default,){
final _that = this;
switch (_that) {
case _GroupSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupSession value)?  $default,){
final _that = this;
switch (_that) {
case _GroupSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String groupId,  String proposedBy,  String proposedByDisplayName,  String? title,  String? game,  DateTime startsAt,  String? notes,  String status,  DateTime createdAt,  DateTime? updatedAt,  List<SessionRsvp> rsvps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupSession() when $default != null:
return $default(_that.id,_that.groupId,_that.proposedBy,_that.proposedByDisplayName,_that.title,_that.game,_that.startsAt,_that.notes,_that.status,_that.createdAt,_that.updatedAt,_that.rsvps);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String groupId,  String proposedBy,  String proposedByDisplayName,  String? title,  String? game,  DateTime startsAt,  String? notes,  String status,  DateTime createdAt,  DateTime? updatedAt,  List<SessionRsvp> rsvps)  $default,) {final _that = this;
switch (_that) {
case _GroupSession():
return $default(_that.id,_that.groupId,_that.proposedBy,_that.proposedByDisplayName,_that.title,_that.game,_that.startsAt,_that.notes,_that.status,_that.createdAt,_that.updatedAt,_that.rsvps);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String groupId,  String proposedBy,  String proposedByDisplayName,  String? title,  String? game,  DateTime startsAt,  String? notes,  String status,  DateTime createdAt,  DateTime? updatedAt,  List<SessionRsvp> rsvps)?  $default,) {final _that = this;
switch (_that) {
case _GroupSession() when $default != null:
return $default(_that.id,_that.groupId,_that.proposedBy,_that.proposedByDisplayName,_that.title,_that.game,_that.startsAt,_that.notes,_that.status,_that.createdAt,_that.updatedAt,_that.rsvps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupSession implements GroupSession {
  const _GroupSession({required this.id, required this.groupId, required this.proposedBy, required this.proposedByDisplayName, this.title, this.game, required this.startsAt, this.notes, required this.status, required this.createdAt, this.updatedAt, final  List<SessionRsvp> rsvps = const []}): _rsvps = rsvps;
  factory _GroupSession.fromJson(Map<String, dynamic> json) => _$GroupSessionFromJson(json);

@override final  String id;
@override final  String groupId;
@override final  String proposedBy;
@override final  String proposedByDisplayName;
@override final  String? title;
@override final  String? game;
@override final  DateTime startsAt;
@override final  String? notes;
@override final  String status;
@override final  DateTime createdAt;
@override final  DateTime? updatedAt;
 final  List<SessionRsvp> _rsvps;
@override@JsonKey() List<SessionRsvp> get rsvps {
  if (_rsvps is EqualUnmodifiableListView) return _rsvps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rsvps);
}


/// Create a copy of GroupSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupSessionCopyWith<_GroupSession> get copyWith => __$GroupSessionCopyWithImpl<_GroupSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupSession&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.proposedBy, proposedBy) || other.proposedBy == proposedBy)&&(identical(other.proposedByDisplayName, proposedByDisplayName) || other.proposedByDisplayName == proposedByDisplayName)&&(identical(other.title, title) || other.title == title)&&(identical(other.game, game) || other.game == game)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._rsvps, _rsvps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,groupId,proposedBy,proposedByDisplayName,title,game,startsAt,notes,status,createdAt,updatedAt,const DeepCollectionEquality().hash(_rsvps));

@override
String toString() {
  return 'GroupSession(id: $id, groupId: $groupId, proposedBy: $proposedBy, proposedByDisplayName: $proposedByDisplayName, title: $title, game: $game, startsAt: $startsAt, notes: $notes, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, rsvps: $rsvps)';
}


}

/// @nodoc
abstract mixin class _$GroupSessionCopyWith<$Res> implements $GroupSessionCopyWith<$Res> {
  factory _$GroupSessionCopyWith(_GroupSession value, $Res Function(_GroupSession) _then) = __$GroupSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String groupId, String proposedBy, String proposedByDisplayName, String? title, String? game, DateTime startsAt, String? notes, String status, DateTime createdAt, DateTime? updatedAt, List<SessionRsvp> rsvps
});




}
/// @nodoc
class __$GroupSessionCopyWithImpl<$Res>
    implements _$GroupSessionCopyWith<$Res> {
  __$GroupSessionCopyWithImpl(this._self, this._then);

  final _GroupSession _self;
  final $Res Function(_GroupSession) _then;

/// Create a copy of GroupSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? proposedBy = null,Object? proposedByDisplayName = null,Object? title = freezed,Object? game = freezed,Object? startsAt = null,Object? notes = freezed,Object? status = null,Object? createdAt = null,Object? updatedAt = freezed,Object? rsvps = null,}) {
  return _then(_GroupSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,proposedBy: null == proposedBy ? _self.proposedBy : proposedBy // ignore: cast_nullable_to_non_nullable
as String,proposedByDisplayName: null == proposedByDisplayName ? _self.proposedByDisplayName : proposedByDisplayName // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,game: freezed == game ? _self.game : game // ignore: cast_nullable_to_non_nullable
as String?,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rsvps: null == rsvps ? _self._rsvps : rsvps // ignore: cast_nullable_to_non_nullable
as List<SessionRsvp>,
  ));
}


}


/// @nodoc
mixin _$GroupActivityEvent {

 String get id; String get groupId; String get actorUserId; String get actorDisplayName; String get type; String get message; String? get sessionId; String? get scheduledReadyWindowId; DateTime get createdAt;
/// Create a copy of GroupActivityEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupActivityEventCopyWith<GroupActivityEvent> get copyWith => _$GroupActivityEventCopyWithImpl<GroupActivityEvent>(this as GroupActivityEvent, _$identity);

  /// Serializes this GroupActivityEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupActivityEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.actorUserId, actorUserId) || other.actorUserId == actorUserId)&&(identical(other.actorDisplayName, actorDisplayName) || other.actorDisplayName == actorDisplayName)&&(identical(other.type, type) || other.type == type)&&(identical(other.message, message) || other.message == message)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.scheduledReadyWindowId, scheduledReadyWindowId) || other.scheduledReadyWindowId == scheduledReadyWindowId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,groupId,actorUserId,actorDisplayName,type,message,sessionId,scheduledReadyWindowId,createdAt);

@override
String toString() {
  return 'GroupActivityEvent(id: $id, groupId: $groupId, actorUserId: $actorUserId, actorDisplayName: $actorDisplayName, type: $type, message: $message, sessionId: $sessionId, scheduledReadyWindowId: $scheduledReadyWindowId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $GroupActivityEventCopyWith<$Res>  {
  factory $GroupActivityEventCopyWith(GroupActivityEvent value, $Res Function(GroupActivityEvent) _then) = _$GroupActivityEventCopyWithImpl;
@useResult
$Res call({
 String id, String groupId, String actorUserId, String actorDisplayName, String type, String message, String? sessionId, String? scheduledReadyWindowId, DateTime createdAt
});




}
/// @nodoc
class _$GroupActivityEventCopyWithImpl<$Res>
    implements $GroupActivityEventCopyWith<$Res> {
  _$GroupActivityEventCopyWithImpl(this._self, this._then);

  final GroupActivityEvent _self;
  final $Res Function(GroupActivityEvent) _then;

/// Create a copy of GroupActivityEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? actorUserId = null,Object? actorDisplayName = null,Object? type = null,Object? message = null,Object? sessionId = freezed,Object? scheduledReadyWindowId = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,actorUserId: null == actorUserId ? _self.actorUserId : actorUserId // ignore: cast_nullable_to_non_nullable
as String,actorDisplayName: null == actorDisplayName ? _self.actorDisplayName : actorDisplayName // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,scheduledReadyWindowId: freezed == scheduledReadyWindowId ? _self.scheduledReadyWindowId : scheduledReadyWindowId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupActivityEvent].
extension GroupActivityEventPatterns on GroupActivityEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupActivityEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupActivityEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupActivityEvent value)  $default,){
final _that = this;
switch (_that) {
case _GroupActivityEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupActivityEvent value)?  $default,){
final _that = this;
switch (_that) {
case _GroupActivityEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String groupId,  String actorUserId,  String actorDisplayName,  String type,  String message,  String? sessionId,  String? scheduledReadyWindowId,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupActivityEvent() when $default != null:
return $default(_that.id,_that.groupId,_that.actorUserId,_that.actorDisplayName,_that.type,_that.message,_that.sessionId,_that.scheduledReadyWindowId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String groupId,  String actorUserId,  String actorDisplayName,  String type,  String message,  String? sessionId,  String? scheduledReadyWindowId,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _GroupActivityEvent():
return $default(_that.id,_that.groupId,_that.actorUserId,_that.actorDisplayName,_that.type,_that.message,_that.sessionId,_that.scheduledReadyWindowId,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String groupId,  String actorUserId,  String actorDisplayName,  String type,  String message,  String? sessionId,  String? scheduledReadyWindowId,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _GroupActivityEvent() when $default != null:
return $default(_that.id,_that.groupId,_that.actorUserId,_that.actorDisplayName,_that.type,_that.message,_that.sessionId,_that.scheduledReadyWindowId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupActivityEvent implements GroupActivityEvent {
  const _GroupActivityEvent({required this.id, required this.groupId, required this.actorUserId, required this.actorDisplayName, required this.type, required this.message, this.sessionId, this.scheduledReadyWindowId, required this.createdAt});
  factory _GroupActivityEvent.fromJson(Map<String, dynamic> json) => _$GroupActivityEventFromJson(json);

@override final  String id;
@override final  String groupId;
@override final  String actorUserId;
@override final  String actorDisplayName;
@override final  String type;
@override final  String message;
@override final  String? sessionId;
@override final  String? scheduledReadyWindowId;
@override final  DateTime createdAt;

/// Create a copy of GroupActivityEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupActivityEventCopyWith<_GroupActivityEvent> get copyWith => __$GroupActivityEventCopyWithImpl<_GroupActivityEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupActivityEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupActivityEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.actorUserId, actorUserId) || other.actorUserId == actorUserId)&&(identical(other.actorDisplayName, actorDisplayName) || other.actorDisplayName == actorDisplayName)&&(identical(other.type, type) || other.type == type)&&(identical(other.message, message) || other.message == message)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.scheduledReadyWindowId, scheduledReadyWindowId) || other.scheduledReadyWindowId == scheduledReadyWindowId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,groupId,actorUserId,actorDisplayName,type,message,sessionId,scheduledReadyWindowId,createdAt);

@override
String toString() {
  return 'GroupActivityEvent(id: $id, groupId: $groupId, actorUserId: $actorUserId, actorDisplayName: $actorDisplayName, type: $type, message: $message, sessionId: $sessionId, scheduledReadyWindowId: $scheduledReadyWindowId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$GroupActivityEventCopyWith<$Res> implements $GroupActivityEventCopyWith<$Res> {
  factory _$GroupActivityEventCopyWith(_GroupActivityEvent value, $Res Function(_GroupActivityEvent) _then) = __$GroupActivityEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String groupId, String actorUserId, String actorDisplayName, String type, String message, String? sessionId, String? scheduledReadyWindowId, DateTime createdAt
});




}
/// @nodoc
class __$GroupActivityEventCopyWithImpl<$Res>
    implements _$GroupActivityEventCopyWith<$Res> {
  __$GroupActivityEventCopyWithImpl(this._self, this._then);

  final _GroupActivityEvent _self;
  final $Res Function(_GroupActivityEvent) _then;

/// Create a copy of GroupActivityEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? actorUserId = null,Object? actorDisplayName = null,Object? type = null,Object? message = null,Object? sessionId = freezed,Object? scheduledReadyWindowId = freezed,Object? createdAt = null,}) {
  return _then(_GroupActivityEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,actorUserId: null == actorUserId ? _self.actorUserId : actorUserId // ignore: cast_nullable_to_non_nullable
as String,actorDisplayName: null == actorDisplayName ? _self.actorDisplayName : actorDisplayName // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,scheduledReadyWindowId: freezed == scheduledReadyWindowId ? _self.scheduledReadyWindowId : scheduledReadyWindowId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
