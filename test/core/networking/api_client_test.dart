import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/networking/api_client.dart';
import 'package:ingame/core/storage/secure_storage.dart';

class _FakeStorage implements SecureStorageService {
  String? accessToken;
  String? refreshToken;

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._fetcher);

  final Future<ResponseBody> Function(RequestOptions options) _fetcher;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _fetcher(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(Object data, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  test('stale refresh does not overwrite newer login tokens', () async {
    final storage = _FakeStorage()
      ..accessToken = 'apple-access-old'
      ..refreshToken = 'apple-refresh-old';

    final refreshStarted = Completer<void>();
    final allowRefreshToComplete = Completer<void>();
    var authInvalidations = 0;

    final refreshDio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'));
    refreshDio.httpClientAdapter = _FakeAdapter((options) async {
      if (options.path == '/auth/refresh') {
        refreshStarted.complete();
        await allowRefreshToComplete.future;
        return _jsonBody({
          'access_token': 'apple-access-refreshed',
          'refresh_token': 'apple-refresh-refreshed',
        }, 200);
      }
      throw UnimplementedError('Unexpected refresh path: ${options.path}');
    });

    final dio = createApiClient(
      baseUrl: 'http://test/api/v1',
      storage: storage,
      onAuthInvalidated: () => authInvalidations++,
      refreshDio: refreshDio,
    );
    dio.httpClientAdapter = _FakeAdapter((options) async {
      final authHeader = options.headers['Authorization'];
      if (options.path == '/users/me' &&
          authHeader == 'Bearer apple-access-old') {
        return _jsonBody({'detail': 'expired'}, 401);
      }
      if (options.path == '/users/me' &&
          authHeader == 'Bearer apple-access-refreshed') {
        return _jsonBody({'id': 'apple-user'}, 200);
      }
      if (options.path == '/users/me' &&
          authHeader == 'Bearer email-access-new') {
        return _jsonBody({'id': 'email-user'}, 200);
      }
      throw UnimplementedError(
        'Unexpected request ${options.path} $authHeader',
      );
    });

    final pendingRequest = dio.get('/users/me');

    await refreshStarted.future;
    await storage.saveTokens(
      accessToken: 'email-access-new',
      refreshToken: 'email-refresh-new',
    );
    allowRefreshToComplete.complete();

    await expectLater(pendingRequest, throwsA(isA<DioException>()));

    expect(storage.accessToken, 'email-access-new');
    expect(storage.refreshToken, 'email-refresh-new');
    expect(authInvalidations, 0);
  });
}
