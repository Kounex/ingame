import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/services/notification_service.dart';
import '../../data/notification_repository.dart';

class NotificationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    ref.watch(sessionResetSignalProvider);
    final authState = ref.watch(authNotifierProvider).value;
    final isAuthenticated =
        authState?.maybeWhen(authenticated: (_) => true, orElse: () => false) ??
        false;

    if (!isAuthenticated) return;
    await _bootstrap();
  }

  Future<void> _bootstrap() async {
    final service = ref.read(notificationServiceProvider);
    if (!service.isSupported) return;

    final repo = ref.read(notificationRepositoryProvider);

    final status = await service.requestPermission();
    if (status != AuthorizationStatus.authorized &&
        status != AuthorizationStatus.provisional) {
      debugPrint('Push notifications not authorized: $status');
      return;
    }

    final token = await service.getToken();
    if (token == null) {
      debugPrint('No FCM token available');
      return;
    }

    await _registerToken(repo, service, token);

    service.onTokenRefresh((newToken) async {
      await _registerToken(repo, service, newToken);
    });

    service.onForegroundMessage((message) {
      debugPrint('Foreground push: ${message.notification?.title}');
    });
  }

  Future<void> _registerToken(
    NotificationRepository repo,
    NotificationService service,
    String token,
  ) async {
    try {
      String? appVersion;
      try {
        final info = await PackageInfo.fromPlatform();
        appVersion = info.version;
      } catch (_) {}

      await repo.registerDevice(
        platform: service.platform,
        token: token,
        appVersion: appVersion,
      );
    } catch (e) {
      debugPrint('Failed to register device token: $e');
    }
  }
}

final notificationNotifierProvider =
    AsyncNotifierProvider<NotificationNotifier, void>(NotificationNotifier.new);
