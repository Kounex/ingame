import 'package:flutter_test/flutter_test.dart';

import 'package:ingame/features/auth/data/oauth_launcher.dart';

void main() {
  test('native Steam callback replaces existing path, query, and fragment', () {
    expect(
      OAuthLauncher.steamReturnToForPlatform(
        isWeb: false,
        appBaseUrl: 'https://in-game.app/groups/abc?foo=bar#frag',
      ),
      'https://in-game.app/auth/steam-callback.html',
    );
  });

  test('native Steam realm ignores existing path, query, and fragment', () {
    expect(
      OAuthLauncher.steamRealmForPlatform(
        isWeb: false,
        appBaseUrl: 'https://in-game.app/groups/abc?foo=bar#frag',
      ),
      'https://in-game.app',
    );
  });

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

  test('treats closed browser window as cancellation', () {
    expect(
      OAuthLauncher.isCancellationError(Exception('User closed the browser')),
      isTrue,
    );
  });

  test('does not treat generic failures as cancellation', () {
    expect(
      OAuthLauncher.isCancellationError(Exception('Server rejected callback')),
      isFalse,
    );
  });

  test('builds Apple display name from given and family name', () {
    expect(
      OAuthLauncher.appleDisplayNameFromParts(
        givenName: 'René',
        familyName: 'Kounex',
      ),
      'René Kounex',
    );
  });

  test('returns null Apple display name when both parts are missing', () {
    expect(
      OAuthLauncher.appleDisplayNameFromParts(
        givenName: null,
        familyName: '  ',
      ),
      isNull,
    );
  });
}
