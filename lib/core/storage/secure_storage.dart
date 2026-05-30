import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SecureStorageService {
  factory SecureStorageService.create() {
    if (kIsWeb) {
      return _WebStorageService();
    }
    return _NativeStorageService();
  }

  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
}

class _NativeStorageService implements SecureStorageService {
  final _storage = const FlutterSecureStorage();

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: SecureStorageService.accessTokenKey, value: accessToken),
      _storage.write(key: SecureStorageService.refreshTokenKey, value: refreshToken),
    ]);
  }

  @override
  Future<String?> getAccessToken() async {
    return _storage.read(key: SecureStorageService.accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return _storage.read(key: SecureStorageService.refreshTokenKey);
  }

  @override
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: SecureStorageService.accessTokenKey),
      _storage.delete(key: SecureStorageService.refreshTokenKey),
    ]);
  }
}

/// On web, flutter_secure_storage may not work reliably.
/// Fall back to SharedPreferences (localStorage under the hood).
class _WebStorageService implements SecureStorageService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await _instance;
    await Future.wait([
      prefs.setString(SecureStorageService.accessTokenKey, accessToken),
      prefs.setString(SecureStorageService.refreshTokenKey, refreshToken),
    ]);
  }

  @override
  Future<String?> getAccessToken() async {
    final prefs = await _instance;
    return prefs.getString(SecureStorageService.accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    final prefs = await _instance;
    return prefs.getString(SecureStorageService.refreshTokenKey);
  }

  @override
  Future<void> clearTokens() async {
    final prefs = await _instance;
    await Future.wait([
      prefs.remove(SecureStorageService.accessTokenKey),
      prefs.remove(SecureStorageService.refreshTokenKey),
    ]);
  }
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService.create();
});
