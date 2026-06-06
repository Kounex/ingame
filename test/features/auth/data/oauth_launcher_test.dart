import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ingame/features/auth/data/oauth_launcher.dart';

void main() {
  test('native Steam callback replaces existing path, query, and fragment', () {
    expect(
      OAuthLauncher.steamReturnToForPlatform(
        isWeb: false,
        webAppBaseUrl: 'https://app.in-game.app/groups/abc?foo=bar#frag',
      ),
      'https://app.in-game.app/auth/steam-callback.html?ingame_native=1',
    );
  });

  test('native Steam realm ignores existing path, query, and fragment', () {
    expect(
      OAuthLauncher.steamRealmForPlatform(
        isWeb: false,
        webAppBaseUrl: 'https://app.in-game.app/groups/abc?foo=bar#frag',
      ),
      'https://app.in-game.app',
    );
  });

  test('native Steam callback uses app base URL callback page', () {
    expect(
      OAuthLauncher.steamReturnToForPlatform(
        isWeb: false,
        webAppBaseUrl: 'http://localhost:8080',
      ),
      'http://localhost:8080/auth/steam-callback.html?ingame_native=1',
    );
  });

  test('native Steam realm uses app base origin', () {
    expect(
      OAuthLauncher.steamRealmForPlatform(
        isWeb: false,
        webAppBaseUrl: 'http://localhost:8080',
      ),
      'http://localhost:8080',
    );
  });

  test('iOS Steam auth keeps custom ingame callback scheme', () {
    expect(
      OAuthLauncher.steamCallbackSchemeForPlatform(
        isWeb: false,
        platform: TargetPlatform.iOS,
      ),
      'ingame',
    );

    expect(
      OAuthLauncher.steamAuthOptionsForPlatform(
        isWeb: false,
        platform: TargetPlatform.iOS,
        webAppBaseUrl: 'https://app.in-game.app/groups/abc?foo=bar#frag',
      ),
      isNull,
    );
  });

  test('Android Steam auth keeps custom ingame callback scheme', () {
    expect(
      OAuthLauncher.steamCallbackSchemeForPlatform(
        isWeb: false,
        platform: TargetPlatform.android,
      ),
      'ingame',
    );
    expect(
      OAuthLauncher.steamAuthOptionsForPlatform(
        isWeb: false,
        platform: TargetPlatform.android,
        webAppBaseUrl: 'https://app.in-game.app',
      ),
      isNull,
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

  test(
    'apple sign-in is unavailable on web without a configured service ID',
    () {
      expect(
        OAuthLauncher.appleSignInAvailableForPlatform(
          isWeb: true,
          platform: TargetPlatform.macOS,
          webServiceId: '',
        ),
        isFalse,
      );
    },
  );

  test('apple sign-in is available on web when a service ID is configured', () {
    expect(
      OAuthLauncher.appleSignInAvailableForPlatform(
        isWeb: true,
        platform: TargetPlatform.windows,
        webServiceId: 'com.ingame.web',
      ),
      isTrue,
    );
  });

  test('apple sign-in is available only on Apple native platforms', () {
    expect(
      OAuthLauncher.appleSignInAvailableForPlatform(
        isWeb: false,
        platform: TargetPlatform.iOS,
        webServiceId: null,
      ),
      isTrue,
    );
    expect(
      OAuthLauncher.appleSignInAvailableForPlatform(
        isWeb: false,
        platform: TargetPlatform.macOS,
        webServiceId: null,
      ),
      isTrue,
    );
    expect(
      OAuthLauncher.appleSignInAvailableForPlatform(
        isWeb: false,
        platform: TargetPlatform.android,
        webServiceId: null,
      ),
      isFalse,
    );
  });
}
