import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class OAuthLauncher {
  OAuthLauncher._();

  static const _callbackScheme = 'ingame';

  static String get _steamReturnTo {
    if (kIsWeb) {
      return '${Uri.base.origin}/auth/steam-callback.html';
    }
    return '$_callbackScheme://auth/steam/callback';
  }

  /// Launches the Steam OpenID 2.0 browser flow and returns the callback
  /// query parameters on success. Throws on cancellation or failure.
  static Future<Map<String, String>> launchSteamAuth() async {
    final returnTo = _steamReturnTo;
    final realm = kIsWeb ? Uri.base.origin : '$_callbackScheme://';

    final authUrl = Uri.https(
      'steamcommunity.com',
      '/openid/login',
      {
        'openid.ns': 'http://specs.openid.net/auth/2.0',
        'openid.mode': 'checkid_setup',
        'openid.return_to': returnTo,
        'openid.realm': realm,
        'openid.identity':
            'http://specs.openid.net/auth/2.0/identifier_select',
        'openid.claimed_id':
            'http://specs.openid.net/auth/2.0/identifier_select',
      },
    );

    // On web, callbackUrlScheme is ignored — flutter_web_auth_2 detects
    // the callback via postMessage from the callback HTML page.
    // The scheme must still be a valid RFC 3986 scheme for native platforms.
    final resultUrl = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: _callbackScheme,
    );

    return Uri.parse(resultUrl).queryParameters;
  }

  /// Launches Apple Sign-In and returns the identity token on success.
  /// On web, requires a configured service ID and redirect URI in Apple
  /// Developer Console. Uses native AuthenticationServices on iOS/macOS.
  /// Throws [SignInWithAppleAuthorizationException] on cancellation.
  static Future<String> launchAppleSignIn() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      webAuthenticationOptions: kIsWeb
          ? WebAuthenticationOptions(
              clientId: const String.fromEnvironment(
                'APPLE_SERVICE_ID',
                defaultValue: 'com.ingame.web',
              ),
              redirectUri: Uri.parse(
                '${Uri.base.origin}/auth/apple-callback.html',
              ),
            )
          : null,
    );

    final identityToken = credential.identityToken;
    if (identityToken == null) {
      throw Exception('Failed to get Apple identity token.');
    }
    return identityToken;
  }

  /// Returns a user-friendly error message for OAuth failures.
  /// In debug mode, includes the original error for easier diagnosis.
  static String friendlyError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('cancel') || message.contains('closed')) {
      return 'Sign-in was cancelled.';
    }
    if (kDebugMode) {
      return 'Authentication failed: $error';
    }
    return 'Authentication failed. Please try again.';
  }
}
