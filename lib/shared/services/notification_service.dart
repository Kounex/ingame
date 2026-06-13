import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/firebase_config.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  bool get isSupported => !kIsWeb || FirebaseConfig.hasWebConfig;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  Future<AuthorizationStatus> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus;
  }

  Future<String?> getToken() async {
    try {
      final vapidKey =
          kIsWeb && FirebaseConfig.vapidKey.isNotEmpty
              ? FirebaseConfig.vapidKey
              : null;
      return await _messaging.getToken(vapidKey: vapidKey);
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  void onTokenRefresh(void Function(String token) callback) {
    _messaging.onTokenRefresh.listen(callback);
  }

  void onForegroundMessage(void Function(RemoteMessage message) callback) {
    FirebaseMessaging.onMessage.listen(callback);
  }

  void onMessageOpenedApp(void Function(RemoteMessage message) callback) {
    FirebaseMessaging.onMessageOpenedApp.listen(callback);
  }

  String get platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'unknown',
    };
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});
