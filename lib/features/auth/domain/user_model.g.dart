// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
  id: json['id'] as String,
  displayName: json['display_name'] as String,
  email: json['email'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  bio: json['bio'] as String?,
  timezone: json['timezone'] as String,
  preferredGamingHours: json['preferred_gaming_hours'] as Map<String, dynamic>?,
  steamId: json['steam_id'] as String?,
  appleId: json['apple_id'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'display_name': instance.displayName,
      'email': instance.email,
      'avatar_url': instance.avatarUrl,
      'bio': instance.bio,
      'timezone': instance.timezone,
      'preferred_gaming_hours': instance.preferredGamingHours,
      'steam_id': instance.steamId,
      'apple_id': instance.appleId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
