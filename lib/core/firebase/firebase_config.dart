import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  FirebaseConfig._();

  static const _apiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const _authDomain = String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN');
  static const _projectId = String.fromEnvironment('FIREBASE_WEB_PROJECT_ID');
  static const _storageBucket =
      String.fromEnvironment('FIREBASE_WEB_STORAGE_BUCKET');
  static const _messagingSenderId =
      String.fromEnvironment('FIREBASE_WEB_MESSAGING_SENDER_ID');
  static const _appId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const vapidKey = String.fromEnvironment('FIREBASE_WEB_VAPID_KEY');

  static bool get hasWebConfig => kIsWeb && _apiKey.isNotEmpty;

  static FirebaseOptions? get webOptions {
    if (!hasWebConfig) return null;
    return const FirebaseOptions(
      apiKey: _apiKey,
      authDomain: _authDomain,
      projectId: _projectId,
      storageBucket: _storageBucket,
      messagingSenderId: _messagingSenderId,
      appId: _appId,
    );
  }
}
