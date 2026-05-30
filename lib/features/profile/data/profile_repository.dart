import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../auth/domain/user_model.dart';

class ProfileRepository {
  ProfileRepository({required this.dio});

  final Dio dio;

  Future<User> getProfile() async {
    final response = await dio.get(ApiEndpoints.usersMe);
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> updateProfile(Map<String, dynamic> updates) async {
    final response = await dio.patch(
      ApiEndpoints.usersMe,
      data: updates,
    );
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> linkSteam(Map<String, String> openidParams) async {
    final response = await dio.post(
      ApiEndpoints.linkSteam,
      data: {'openid_params': openidParams},
    );
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> linkApple(String identityToken) async {
    final response = await dio.post(
      ApiEndpoints.linkApple,
      data: {'identity_token': identityToken},
    );
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> unlinkSteam() async {
    final response = await dio.delete(ApiEndpoints.linkSteam);
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> unlinkApple() async {
    final response = await dio.delete(ApiEndpoints.linkApple);
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> setEmailPassword({
    required String email,
    required String password,
  }) async {
    final response = await dio.post(
      ApiEndpoints.setEmailPassword,
      data: {'email': email, 'password': password},
    );
    return User.fromJson(response.data as Map<String, dynamic>);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(dio: ref.read(dioProvider));
});
