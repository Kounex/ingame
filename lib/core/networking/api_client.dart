import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_session.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

typedef AuthInvalidationCallback = void Function();

bool _sessionChanged({
  required String refreshToken,
  required String? currentRefreshToken,
}) {
  return currentRefreshToken != refreshToken;
}

Future<bool> _tryRefreshSession({
  required Dio dio,
  required Dio refreshDio,
  required SecureStorageService storage,
  required RequestOptions failedRequest,
  required AuthInvalidationCallback onAuthInvalidated,
  required ErrorInterceptorHandler handler,
}) async {
  final refreshToken = await storage.getRefreshToken();
  if (refreshToken == null) {
    return false;
  }

  try {
    final response = await refreshDio.post(
      ApiEndpoints.refreshToken,
      data: {'refresh_token': refreshToken},
    );
    final currentRefreshToken = await storage.getRefreshToken();
    if (_sessionChanged(
      refreshToken: refreshToken,
      currentRefreshToken: currentRefreshToken,
    )) {
      return false;
    }

    final newAccessToken = response.data['access_token'] as String;
    final newRefreshToken = response.data['refresh_token'] as String;
    await storage.saveTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    );
    failedRequest.headers['Authorization'] = 'Bearer $newAccessToken';
    final retryResponse = await dio.fetch(failedRequest);
    handler.resolve(retryResponse);
    return true;
  } catch (_) {
    final currentRefreshToken = await storage.getRefreshToken();
    if (_sessionChanged(
      refreshToken: refreshToken,
      currentRefreshToken: currentRefreshToken,
    )) {
      return false;
    }

    await storage.clearTokens();
    onAuthInvalidated();
    return false;
  }
}

Dio createApiClient({
  required String baseUrl,
  required SecureStorageService storage,
  required AuthInvalidationCallback onAuthInvalidated,
  Dio? refreshDio,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  final refreshClient =
      refreshDio ??
      Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final didRefresh = await _tryRefreshSession(
            dio: dio,
            refreshDio: refreshClient,
            storage: storage,
            failedRequest: error.requestOptions,
            onAuthInvalidated: onAuthInvalidated,
            handler: handler,
          );
          if (didRefresh) {
            return;
          }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(secureStorageProvider);
  return createApiClient(
    baseUrl: ApiEndpoints.baseUrl,
    storage: storage,
    onAuthInvalidated: () {
      ref.read(authInvalidationSignalProvider.notifier).state++;
    },
  );
});
