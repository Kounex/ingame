import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ingame/core/networking/api_endpoints.dart';
import 'package:ingame/features/profile/data/profile_repository.dart';

void main() {
  test(
    'upsertManualSocialIdentity uses provider endpoint and nullable payload',
    () async {
      final dio = Dio();
      final repository = ProfileRepository(dio: dio);

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, ApiEndpoints.socialIdentity('playstation'));
            expect(options.data, {
              'external_id': null,
              'username': null,
              'display_name': null,
              'profile_url': 'https://profile.playstation.com/PSHero',
            });
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'id': 'user-1',
                  'display_name': 'Profile User',
                  'timezone': 'UTC',
                },
              ),
            );
          },
        ),
      );

      final user = await repository.upsertManualSocialIdentity(
        provider: 'playstation',
        profileUrl: 'https://profile.playstation.com/PSHero',
      );

      expect(user.displayName, 'Profile User');
    },
  );

  test('deleteManualSocialIdentity uses provider endpoint', () async {
    final dio = Dio();
    final repository = ProfileRepository(dio: dio);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, ApiEndpoints.socialIdentity('nintendo'));
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'id': 'user-1',
                'display_name': 'Profile User',
                'timezone': 'UTC',
              },
            ),
          );
        },
      ),
    );

    final user = await repository.deleteManualSocialIdentity('nintendo');

    expect(user.displayName, 'Profile User');
  });
}
