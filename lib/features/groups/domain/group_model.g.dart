// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Group _$GroupFromJson(Map<String, dynamic> json) => _Group(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  inviteCode: json['invite_code'] as String,
  isDiscoverable: json['is_discoverable'] as bool,
  joinMode: json['join_mode'] as String,
  avatarUrl: json['avatar_url'] as String?,
  createdBy: json['created_by'] as String,
  memberCount: (json['member_count'] as num).toInt(),
  hasPendingJoinRequest: json['has_pending_join_request'] as bool? ?? false,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$GroupToJson(_Group instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'invite_code': instance.inviteCode,
  'is_discoverable': instance.isDiscoverable,
  'join_mode': instance.joinMode,
  'avatar_url': instance.avatarUrl,
  'created_by': instance.createdBy,
  'member_count': instance.memberCount,
  'has_pending_join_request': instance.hasPendingJoinRequest,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
