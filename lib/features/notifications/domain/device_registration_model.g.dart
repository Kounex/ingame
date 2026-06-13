// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_registration_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeviceRegistration _$DeviceRegistrationFromJson(Map<String, dynamic> json) =>
    _DeviceRegistration(
      id: json['id'] as String,
      platform: json['platform'] as String,
      token: json['token'] as String,
      deviceLabel: json['device_label'] as String?,
      lastSeenAt: json['last_seen_at'] == null
          ? null
          : DateTime.parse(json['last_seen_at'] as String),
    );

Map<String, dynamic> _$DeviceRegistrationToJson(_DeviceRegistration instance) =>
    <String, dynamic>{
      'id': instance.id,
      'platform': instance.platform,
      'token': instance.token,
      'device_label': instance.deviceLabel,
      'last_seen_at': instance.lastSeenAt?.toIso8601String(),
    };
