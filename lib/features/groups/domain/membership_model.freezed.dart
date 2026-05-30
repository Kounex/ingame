// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'membership_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GroupMember _$GroupMemberFromJson(Map<String, dynamic> json) {
  return _GroupMember.fromJson(json);
}

/// @nodoc
mixin _$GroupMember {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  DateTime? get joinedAt => throw _privateConstructorUsedError;

  /// Serializes this GroupMember to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GroupMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroupMemberCopyWith<GroupMember> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupMemberCopyWith<$Res> {
  factory $GroupMemberCopyWith(
    GroupMember value,
    $Res Function(GroupMember) then,
  ) = _$GroupMemberCopyWithImpl<$Res, GroupMember>;
  @useResult
  $Res call({
    String id,
    String userId,
    String displayName,
    String? avatarUrl,
    String role,
    DateTime? joinedAt,
  });
}

/// @nodoc
class _$GroupMemberCopyWithImpl<$Res, $Val extends GroupMember>
    implements $GroupMemberCopyWith<$Res> {
  _$GroupMemberCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroupMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? displayName = null,
    Object? avatarUrl = freezed,
    Object? role = null,
    Object? joinedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            avatarUrl: freezed == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as String,
            joinedAt: freezed == joinedAt
                ? _value.joinedAt
                : joinedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GroupMemberImplCopyWith<$Res>
    implements $GroupMemberCopyWith<$Res> {
  factory _$$GroupMemberImplCopyWith(
    _$GroupMemberImpl value,
    $Res Function(_$GroupMemberImpl) then,
  ) = __$$GroupMemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String displayName,
    String? avatarUrl,
    String role,
    DateTime? joinedAt,
  });
}

/// @nodoc
class __$$GroupMemberImplCopyWithImpl<$Res>
    extends _$GroupMemberCopyWithImpl<$Res, _$GroupMemberImpl>
    implements _$$GroupMemberImplCopyWith<$Res> {
  __$$GroupMemberImplCopyWithImpl(
    _$GroupMemberImpl _value,
    $Res Function(_$GroupMemberImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GroupMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? displayName = null,
    Object? avatarUrl = freezed,
    Object? role = null,
    Object? joinedAt = freezed,
  }) {
    return _then(
      _$GroupMemberImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        avatarUrl: freezed == avatarUrl
            ? _value.avatarUrl
            : avatarUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
        joinedAt: freezed == joinedAt
            ? _value.joinedAt
            : joinedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupMemberImpl implements _GroupMember {
  const _$GroupMemberImpl({
    required this.id,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.role,
    this.joinedAt,
  });

  factory _$GroupMemberImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupMemberImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String displayName;
  @override
  final String? avatarUrl;
  @override
  final String role;
  @override
  final DateTime? joinedAt;

  @override
  String toString() {
    return 'GroupMember(id: $id, userId: $userId, displayName: $displayName, avatarUrl: $avatarUrl, role: $role, joinedAt: $joinedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupMemberImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    displayName,
    avatarUrl,
    role,
    joinedAt,
  );

  /// Create a copy of GroupMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupMemberImplCopyWith<_$GroupMemberImpl> get copyWith =>
      __$$GroupMemberImplCopyWithImpl<_$GroupMemberImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupMemberImplToJson(this);
  }
}

abstract class _GroupMember implements GroupMember {
  const factory _GroupMember({
    required final String id,
    required final String userId,
    required final String displayName,
    final String? avatarUrl,
    required final String role,
    final DateTime? joinedAt,
  }) = _$GroupMemberImpl;

  factory _GroupMember.fromJson(Map<String, dynamic> json) =
      _$GroupMemberImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get displayName;
  @override
  String? get avatarUrl;
  @override
  String get role;
  @override
  DateTime? get joinedAt;

  /// Create a copy of GroupMember
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroupMemberImplCopyWith<_$GroupMemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

JoinRequestUser _$JoinRequestUserFromJson(Map<String, dynamic> json) {
  return _JoinRequestUser.fromJson(json);
}

/// @nodoc
mixin _$JoinRequestUser {
  String get id => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;

  /// Serializes this JoinRequestUser to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JoinRequestUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JoinRequestUserCopyWith<JoinRequestUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JoinRequestUserCopyWith<$Res> {
  factory $JoinRequestUserCopyWith(
    JoinRequestUser value,
    $Res Function(JoinRequestUser) then,
  ) = _$JoinRequestUserCopyWithImpl<$Res, JoinRequestUser>;
  @useResult
  $Res call({String id, String displayName, String? avatarUrl});
}

/// @nodoc
class _$JoinRequestUserCopyWithImpl<$Res, $Val extends JoinRequestUser>
    implements $JoinRequestUserCopyWith<$Res> {
  _$JoinRequestUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JoinRequestUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? avatarUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            avatarUrl: freezed == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$JoinRequestUserImplCopyWith<$Res>
    implements $JoinRequestUserCopyWith<$Res> {
  factory _$$JoinRequestUserImplCopyWith(
    _$JoinRequestUserImpl value,
    $Res Function(_$JoinRequestUserImpl) then,
  ) = __$$JoinRequestUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String displayName, String? avatarUrl});
}

/// @nodoc
class __$$JoinRequestUserImplCopyWithImpl<$Res>
    extends _$JoinRequestUserCopyWithImpl<$Res, _$JoinRequestUserImpl>
    implements _$$JoinRequestUserImplCopyWith<$Res> {
  __$$JoinRequestUserImplCopyWithImpl(
    _$JoinRequestUserImpl _value,
    $Res Function(_$JoinRequestUserImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of JoinRequestUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? avatarUrl = freezed,
  }) {
    return _then(
      _$JoinRequestUserImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        avatarUrl: freezed == avatarUrl
            ? _value.avatarUrl
            : avatarUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$JoinRequestUserImpl implements _JoinRequestUser {
  const _$JoinRequestUserImpl({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  factory _$JoinRequestUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$JoinRequestUserImplFromJson(json);

  @override
  final String id;
  @override
  final String displayName;
  @override
  final String? avatarUrl;

  @override
  String toString() {
    return 'JoinRequestUser(id: $id, displayName: $displayName, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JoinRequestUserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, displayName, avatarUrl);

  /// Create a copy of JoinRequestUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JoinRequestUserImplCopyWith<_$JoinRequestUserImpl> get copyWith =>
      __$$JoinRequestUserImplCopyWithImpl<_$JoinRequestUserImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$JoinRequestUserImplToJson(this);
  }
}

abstract class _JoinRequestUser implements JoinRequestUser {
  const factory _JoinRequestUser({
    required final String id,
    required final String displayName,
    final String? avatarUrl,
  }) = _$JoinRequestUserImpl;

  factory _JoinRequestUser.fromJson(Map<String, dynamic> json) =
      _$JoinRequestUserImpl.fromJson;

  @override
  String get id;
  @override
  String get displayName;
  @override
  String? get avatarUrl;

  /// Create a copy of JoinRequestUser
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JoinRequestUserImplCopyWith<_$JoinRequestUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

JoinRequest _$JoinRequestFromJson(Map<String, dynamic> json) {
  return _JoinRequest.fromJson(json);
}

/// @nodoc
mixin _$JoinRequest {
  String get id => throw _privateConstructorUsedError;
  JoinRequestUser get user => throw _privateConstructorUsedError;
  String get groupId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  String? get resolvedBy => throw _privateConstructorUsedError;
  DateTime? get resolvedAt => throw _privateConstructorUsedError;

  /// Serializes this JoinRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JoinRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JoinRequestCopyWith<JoinRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JoinRequestCopyWith<$Res> {
  factory $JoinRequestCopyWith(
    JoinRequest value,
    $Res Function(JoinRequest) then,
  ) = _$JoinRequestCopyWithImpl<$Res, JoinRequest>;
  @useResult
  $Res call({
    String id,
    JoinRequestUser user,
    String groupId,
    String status,
    DateTime? createdAt,
    String? resolvedBy,
    DateTime? resolvedAt,
  });

  $JoinRequestUserCopyWith<$Res> get user;
}

/// @nodoc
class _$JoinRequestCopyWithImpl<$Res, $Val extends JoinRequest>
    implements $JoinRequestCopyWith<$Res> {
  _$JoinRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JoinRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? user = null,
    Object? groupId = null,
    Object? status = null,
    Object? createdAt = freezed,
    Object? resolvedBy = freezed,
    Object? resolvedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            user: null == user
                ? _value.user
                : user // ignore: cast_nullable_to_non_nullable
                      as JoinRequestUser,
            groupId: null == groupId
                ? _value.groupId
                : groupId // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            resolvedBy: freezed == resolvedBy
                ? _value.resolvedBy
                : resolvedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            resolvedAt: freezed == resolvedAt
                ? _value.resolvedAt
                : resolvedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of JoinRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JoinRequestUserCopyWith<$Res> get user {
    return $JoinRequestUserCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$JoinRequestImplCopyWith<$Res>
    implements $JoinRequestCopyWith<$Res> {
  factory _$$JoinRequestImplCopyWith(
    _$JoinRequestImpl value,
    $Res Function(_$JoinRequestImpl) then,
  ) = __$$JoinRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    JoinRequestUser user,
    String groupId,
    String status,
    DateTime? createdAt,
    String? resolvedBy,
    DateTime? resolvedAt,
  });

  @override
  $JoinRequestUserCopyWith<$Res> get user;
}

/// @nodoc
class __$$JoinRequestImplCopyWithImpl<$Res>
    extends _$JoinRequestCopyWithImpl<$Res, _$JoinRequestImpl>
    implements _$$JoinRequestImplCopyWith<$Res> {
  __$$JoinRequestImplCopyWithImpl(
    _$JoinRequestImpl _value,
    $Res Function(_$JoinRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of JoinRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? user = null,
    Object? groupId = null,
    Object? status = null,
    Object? createdAt = freezed,
    Object? resolvedBy = freezed,
    Object? resolvedAt = freezed,
  }) {
    return _then(
      _$JoinRequestImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        user: null == user
            ? _value.user
            : user // ignore: cast_nullable_to_non_nullable
                  as JoinRequestUser,
        groupId: null == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        resolvedBy: freezed == resolvedBy
            ? _value.resolvedBy
            : resolvedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        resolvedAt: freezed == resolvedAt
            ? _value.resolvedAt
            : resolvedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$JoinRequestImpl implements _JoinRequest {
  const _$JoinRequestImpl({
    required this.id,
    required this.user,
    required this.groupId,
    required this.status,
    this.createdAt,
    this.resolvedBy,
    this.resolvedAt,
  });

  factory _$JoinRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$JoinRequestImplFromJson(json);

  @override
  final String id;
  @override
  final JoinRequestUser user;
  @override
  final String groupId;
  @override
  final String status;
  @override
  final DateTime? createdAt;
  @override
  final String? resolvedBy;
  @override
  final DateTime? resolvedAt;

  @override
  String toString() {
    return 'JoinRequest(id: $id, user: $user, groupId: $groupId, status: $status, createdAt: $createdAt, resolvedBy: $resolvedBy, resolvedAt: $resolvedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JoinRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.resolvedBy, resolvedBy) ||
                other.resolvedBy == resolvedBy) &&
            (identical(other.resolvedAt, resolvedAt) ||
                other.resolvedAt == resolvedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    user,
    groupId,
    status,
    createdAt,
    resolvedBy,
    resolvedAt,
  );

  /// Create a copy of JoinRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JoinRequestImplCopyWith<_$JoinRequestImpl> get copyWith =>
      __$$JoinRequestImplCopyWithImpl<_$JoinRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JoinRequestImplToJson(this);
  }
}

abstract class _JoinRequest implements JoinRequest {
  const factory _JoinRequest({
    required final String id,
    required final JoinRequestUser user,
    required final String groupId,
    required final String status,
    final DateTime? createdAt,
    final String? resolvedBy,
    final DateTime? resolvedAt,
  }) = _$JoinRequestImpl;

  factory _JoinRequest.fromJson(Map<String, dynamic> json) =
      _$JoinRequestImpl.fromJson;

  @override
  String get id;
  @override
  JoinRequestUser get user;
  @override
  String get groupId;
  @override
  String get status;
  @override
  DateTime? get createdAt;
  @override
  String? get resolvedBy;
  @override
  DateTime? get resolvedAt;

  /// Create a copy of JoinRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JoinRequestImplCopyWith<_$JoinRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
