// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_identity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProviderIdentity _$ProviderIdentityFromJson(Map<String, dynamic> json) =>
    ProviderIdentity(
      provider: json['provider'] as String,
      authMode: json['auth_mode'] as String,
      externalId: json['external_id'] as String?,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      profileUrl: json['profile_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      lastSyncedAt: json['last_synced_at'] == null
          ? null
          : DateTime.parse(json['last_synced_at'] as String),
      supportsLogin: json['supports_login'] as bool,
      supportsRefresh: json['supports_refresh'] as bool,
      supportsDirectProfileLink: json['supports_direct_profile_link'] as bool,
      supportsManualEntry: json['supports_manual_entry'] as bool,
      supportsCopyOnlyAction: json['supports_copy_only_action'] as bool,
      isSocialIdentity: json['is_social_identity'] as bool,
    );

Map<String, dynamic> _$ProviderIdentityToJson(ProviderIdentity instance) =>
    <String, dynamic>{
      'provider': instance.provider,
      'auth_mode': instance.authMode,
      'external_id': instance.externalId,
      'username': instance.username,
      'display_name': instance.displayName,
      'email': instance.email,
      'avatar_url': instance.avatarUrl,
      'profile_url': instance.profileUrl,
      'metadata': instance.metadata,
      'last_synced_at': instance.lastSyncedAt?.toIso8601String(),
      'supports_login': instance.supportsLogin,
      'supports_refresh': instance.supportsRefresh,
      'supports_direct_profile_link': instance.supportsDirectProfileLink,
      'supports_manual_entry': instance.supportsManualEntry,
      'supports_copy_only_action': instance.supportsCopyOnlyAction,
      'is_social_identity': instance.isSocialIdentity,
    };
