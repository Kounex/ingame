import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../domain/device_registration_model.dart';

class NotificationRepository {
  NotificationRepository({required this.dio});

  final Dio dio;

  Future<DeviceRegistration> registerDevice({
    required String platform,
    required String token,
    String? deviceLabel,
    String? appVersion,
  }) async {
    final response = await dio.post(
      ApiEndpoints.deviceRegistrations,
      data: {
        'platform': platform,
        'token': token,
        ?if (deviceLabel != null) 'device_label': deviceLabel,
        ?if (appVersion != null) 'app_version': appVersion,
      },
    );
    return DeviceRegistration.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<DeviceRegistration>> listDeviceRegistrations() async {
    final response = await dio.get(ApiEndpoints.deviceRegistrations);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => DeviceRegistration.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteDeviceRegistration(String id) async {
    await dio.delete(ApiEndpoints.deviceRegistration(id));
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(dio: ref.read(dioProvider));
});
