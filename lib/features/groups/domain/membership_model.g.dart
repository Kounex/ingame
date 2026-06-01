// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroupMember _$GroupMemberFromJson(Map<String, dynamic> json) => _GroupMember(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  displayName: json['display_name'] as String,
  avatarUrl: json['avatar_url'] as String?,
  role: json['role'] as String,
  joinedAt: json['joined_at'] == null
      ? null
      : DateTime.parse(json['joined_at'] as String),
);

Map<String, dynamic> _$GroupMemberToJson(_GroupMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'display_name': instance.displayName,
      'avatar_url': instance.avatarUrl,
      'role': instance.role,
      'joined_at': instance.joinedAt?.toIso8601String(),
    };

_JoinRequestUser _$JoinRequestUserFromJson(Map<String, dynamic> json) =>
    _JoinRequestUser(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );

Map<String, dynamic> _$JoinRequestUserToJson(_JoinRequestUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'display_name': instance.displayName,
      'avatar_url': instance.avatarUrl,
    };

_JoinRequest _$JoinRequestFromJson(Map<String, dynamic> json) => _JoinRequest(
  id: json['id'] as String,
  user: JoinRequestUser.fromJson(json['user'] as Map<String, dynamic>),
  groupId: json['group_id'] as String,
  status: json['status'] as String,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  resolvedBy: json['resolved_by'] as String?,
  resolvedAt: json['resolved_at'] == null
      ? null
      : DateTime.parse(json['resolved_at'] as String),
);

Map<String, dynamic> _$JoinRequestToJson(_JoinRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user,
      'group_id': instance.groupId,
      'status': instance.status,
      'created_at': instance.createdAt?.toIso8601String(),
      'resolved_by': instance.resolvedBy,
      'resolved_at': instance.resolvedAt?.toIso8601String(),
    };
