import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_registration_model.freezed.dart';
part 'device_registration_model.g.dart';

@freezed
abstract class DeviceRegistration with _$DeviceRegistration {
  const factory DeviceRegistration({
    required String id,
    required String platform,
    required String token,
    String? deviceLabel,
    DateTime? lastSeenAt,
  }) = _DeviceRegistration;

  factory DeviceRegistration.fromJson(Map<String, dynamic> json) =>
      _$DeviceRegistrationFromJson(json);
}
