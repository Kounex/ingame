import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_session.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiEndpoints.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  final storage = ref.read(secureStorageProvider);

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        final refreshToken = await storage.getRefreshToken();
        if (refreshToken != null) {
          try {
            final response = await Dio().post(
              '${ApiEndpoints.baseUrl}${ApiEndpoints.refreshToken}',
              data: {'refresh_token': refreshToken},
            );
            final newAccessToken = response.data['access_token'] as String;
            final newRefreshToken = response.data['refresh_token'] as String;
            await storage.saveTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
            );
            error.requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';
            final retryResponse = await dio.fetch(error.requestOptions);
            handler.resolve(retryResponse);
            return;
          } catch (_) {
            await storage.clearTokens();
            ref.read(authInvalidationSignalProvider.notifier).state++;
          }
        }
      }
      handler.next(error);
    },
  ));

  return dio;
});
