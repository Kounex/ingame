import 'package:flutter_test/flutter_test.dart';

import 'package:ingame/features/auth/data/oauth_launcher.dart';

void main() {
  test('native Steam callback uses app base URL callback page', () {
    expect(
      OAuthLauncher.steamReturnToForPlatform(
        isWeb: false,
        appBaseUrl: 'http://localhost:8080',
      ),
      'http://localhost:8080/auth/steam-callback.html',
    );
  });

  test('native Steam realm uses app base origin', () {
    expect(
      OAuthLauncher.steamRealmForPlatform(
        isWeb: false,
        appBaseUrl: 'http://localhost:8080',
      ),
      'http://localhost:8080',
    );
  });
}
