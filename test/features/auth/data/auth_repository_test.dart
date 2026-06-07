import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/networking/api_endpoints.dart';
import 'package:ingame/core/storage/secure_storage.dart';
import 'package:ingame/features/auth/data/auth_repository.dart';

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

void main() {
  test('steam auth wraps openid params in request body', () async {
    final dio = Dio();
    final storage = _FakeStorage();
    final repository = AuthRepository(dio: dio, storage: storage);
    final params = <String, String>{
      'openid.claimed_id':
          'https://steamcommunity.com/openid/id/76561198000000001',
      'openid.sig': 'signature',
    };

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, ApiEndpoints.steamAuth);
          expect(options.data, {'openid_params': params});

          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'access_token': 'access-token',
                'refresh_token': 'refresh-token',
                'user': {
                  'id': 'user-1',
                  'display_name': 'Steam User',
                  'timezone': 'Europe/Berlin',
                  'steam_id': '76561198000000001',
                },
              },
            ),
          );
        },
      ),
    );

    final user = await repository.steamAuth(params);

    expect(user.displayName, 'Steam User');
    expect(storage.accessToken, 'access-token');
    expect(storage.refreshToken, 'refresh-token');
  });

  test('apple auth includes optional display name in request body', () async {
    final dio = Dio();
    final storage = _FakeStorage();
    final repository = AuthRepository(dio: dio, storage: storage);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, ApiEndpoints.appleAuth);
          expect(options.data, {
            'identity_token': 'apple-token',
            'display_name': 'René Kounex',
          });

          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'access_token': 'access-token',
                'refresh_token': 'refresh-token',
                'user': {
                  'id': 'user-1',
                  'display_name': 'René Kounex',
                  'timezone': 'Europe/Berlin',
                  'apple_id': 'apple-user-123',
                },
              },
            ),
          );
        },
      ),
    );

    final user = await repository.appleAuth(
      'apple-token',
      displayName: 'René Kounex',
    );

    expect(user.displayName, 'René Kounex');
    expect(storage.accessToken, 'access-token');
    expect(storage.refreshToken, 'refresh-token');
  });

  test('discord auth wraps pkce callback payload in request body', () async {
    final dio = Dio();
    final storage = _FakeStorage();
    final repository = AuthRepository(dio: dio, storage: storage);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, ApiEndpoints.discordAuth);
          expect(options.data, {
            'code': 'discord-auth-code',
            'code_verifier':
                'discord-code-verifier-discord-code-verifier-12345',
            'redirect_uri': 'ingame://auth/discord/callback',
          });

          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'access_token': 'access-token',
                'refresh_token': 'refresh-token',
                'user': {
                  'id': 'user-1',
                  'display_name': 'Discord Hero',
                  'email': 'discord@example.com',
                  'timezone': 'Europe/Berlin',
                  'provider_identities': [
                    {
                      'provider': 'discord',
                      'auth_mode': 'official_oauth',
                      'external_id': 'discord-user-123',
                      'username': 'discord_user',
                      'display_name': 'Discord Hero',
                      'email': 'discord@example.com',
                      'avatar_url': 'https://cdn.discord.test/avatar.png',
                      'profile_url':
                          'https://discord.com/users/discord-user-123',
                      'metadata': null,
                      'last_synced_at': '2026-06-07T10:00:00Z',
                      'supports_login': true,
                      'supports_refresh': true,
                      'supports_direct_profile_link': true,
                      'supports_manual_entry': false,
                      'supports_copy_only_action': false,
                      'is_social_identity': true,
                    },
                  ],
                },
              },
            ),
          );
        },
      ),
    );

    final user = await repository.discordAuth(
      code: 'discord-auth-code',
      codeVerifier: 'discord-code-verifier-discord-code-verifier-12345',
      redirectUri: 'ingame://auth/discord/callback',
    );

    expect(user.displayName, 'Discord Hero');
    expect(user.providerIdentities.single.provider, 'discord');
    expect(user.providerIdentities.single.profileUrl, 'https://discord.com/users/discord-user-123');
    expect(storage.accessToken, 'access-token');
    expect(storage.refreshToken, 'refresh-token');
  });
}
