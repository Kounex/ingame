import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/user_model.dart';

class AuthRepository {
  AuthRepository({required this.dio, required this.storage});

  final Dio dio;
  final SecureStorageService storage;

  Future<User> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await dio.post(
      ApiEndpoints.register,
      data: {
        'email': email,
        'password': password,
        'display_name': displayName,
      },
    );
    await storage.saveTokens(
      accessToken: response.data['access_token'] as String,
      refreshToken: response.data['refresh_token'] as String,
    );
    return User.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await dio.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );
    await storage.saveTokens(
      accessToken: response.data['access_token'] as String,
      refreshToken: response.data['refresh_token'] as String,
    );
    return User.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<bool> checkEmailAvailable(String email) async {
    final response = await dio.post(
      ApiEndpoints.checkEmail,
      data: {'value': email},
    );
    return response.data['available'] as bool;
  }

  Future<bool> checkDisplayNameAvailable(String displayName) async {
    final response = await dio.post(
      ApiEndpoints.checkDisplayName,
      data: {'value': displayName},
    );
    return response.data['available'] as bool;
  }

  Future<User> getCurrentUser() async {
    final response = await dio.get(ApiEndpoints.usersMe);
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await storage.clearTokens();
  }

  Future<User> steamAuth(Map<String, String> params) async {
    final response = await dio.post(
      ApiEndpoints.steamAuth,
      data: {'openid_params': params},
    );
    await storage.saveTokens(
      accessToken: response.data['access_token'] as String,
      refreshToken: response.data['refresh_token'] as String,
    );
    return User.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<User> appleAuth(String identityToken) async {
    final response = await dio.post(
      ApiEndpoints.appleAuth,
      data: {'identity_token': identityToken},
    );
    await storage.saveTokens(
      accessToken: response.data['access_token'] as String,
      refreshToken: response.data['refresh_token'] as String,
    );
    return User.fromJson(response.data['user'] as Map<String, dynamic>);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.read(dioProvider),
    storage: ref.read(secureStorageProvider),
  );
});
