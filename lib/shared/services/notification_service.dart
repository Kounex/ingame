import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  Future<AuthorizationStatus> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus;
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
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
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});
