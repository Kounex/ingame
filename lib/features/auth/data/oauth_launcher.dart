import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/networking/api_error.dart';
import '../../../core/networking/app_failure.dart';
import '../../../core/networking/api_endpoints.dart';

class AppleSignInResult {
  const AppleSignInResult({required this.identityToken, this.displayName});

  final String identityToken;
  final String? displayName;
}

class AppleSignInUnavailableException implements Exception {
  const AppleSignInUnavailableException();
}

class OAuthLauncher {
  OAuthLauncher._();

  static const _callbackScheme = 'ingame';
  static const _steamCallbackPath = '/auth/steam-callback.html';
  static const _nativeBridgeParam = 'ingame_native';
  static const _appleCallbackPath = '/auth/apple-callback.html';
  static const _appleWebServiceId = String.fromEnvironment('APPLE_SERVICE_ID');

  static String get _steamReturnTo {
    return steamReturnToForPlatform(
      isWeb: kIsWeb,
      webAppBaseUrl: ApiEndpoints.webAppBaseUrl,
    );
  }

  static String get _steamRealm {
    return steamRealmForPlatform(
      isWeb: kIsWeb,
      webAppBaseUrl: ApiEndpoints.webAppBaseUrl,
    );
  }

  @visibleForTesting
  static String steamReturnToForPlatform({
    required bool isWeb,
    required String webAppBaseUrl,
  }) {
    if (isWeb) {
      return '${Uri.base.origin}$_steamCallbackPath';
    }

    return _steamCallbackUri(
      webAppBaseUrl,
      queryParameters: const {_nativeBridgeParam: '1'},
    ).toString();
  }

  @visibleForTesting
  static String steamRealmForPlatform({
    required bool isWeb,
    required String webAppBaseUrl,
  }) {
    if (isWeb) {
      return Uri.base.origin;
    }

    return _steamCallbackUri(webAppBaseUrl).origin;
  }

  static Uri _steamCallbackUri(
    String webAppBaseUrl, {
    Map<String, String>? queryParameters,
  }) {
    final appUri = Uri.parse(webAppBaseUrl);
    return Uri(
      scheme: appUri.scheme,
      host: appUri.host,
      port: appUri.hasPort ? appUri.port : null,
      path: _steamCallbackPath,
      queryParameters: queryParameters,
    );
  }

  @visibleForTesting
  static String steamCallbackSchemeForPlatform({
    required bool isWeb,
    required TargetPlatform platform,
  }) {
    if (isWeb) {
      return _callbackScheme;
    }

    return _callbackScheme;
  }

  @visibleForTesting
  static FlutterWebAuth2Options? steamAuthOptionsForPlatform({
    required bool isWeb,
    required TargetPlatform platform,
    required String webAppBaseUrl,
  }) {
    return null;
  }

  /// Launches the Steam OpenID 2.0 browser flow and returns the callback
  /// query parameters on success. Throws on cancellation or failure.
  static Future<Map<String, String>> launchSteamAuth() async {
    final returnTo = _steamReturnTo;
    final realm = _steamRealm;
    final callbackUrlScheme = steamCallbackSchemeForPlatform(
      isWeb: kIsWeb,
      platform: defaultTargetPlatform,
    );
    final options = steamAuthOptionsForPlatform(
      isWeb: kIsWeb,
      platform: defaultTargetPlatform,
      webAppBaseUrl: ApiEndpoints.webAppBaseUrl,
    );

    final authUrl = Uri.https('steamcommunity.com', '/openid/login', {
      'openid.ns': 'http://specs.openid.net/auth/2.0',
      'openid.mode': 'checkid_setup',
      'openid.return_to': returnTo,
      'openid.realm': realm,
      'openid.identity': 'http://specs.openid.net/auth/2.0/identifier_select',
      'openid.claimed_id': 'http://specs.openid.net/auth/2.0/identifier_select',
    });

    // On web, callbackUrlScheme is ignored — flutter_web_auth_2 detects
    // the callback via postMessage from the callback HTML page. Native
    // platforms bridge from the hosted callback page back into ingame://.
    final resultUrl = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: callbackUrlScheme,
      options: options ?? const FlutterWebAuth2Options(),
    );

    return Uri.parse(resultUrl).queryParameters;
  }

  @visibleForTesting
  static String? appleDisplayNameFromParts({
    required String? givenName,
    required String? familyName,
  }) {
    final parts = [
      givenName?.trim(),
      familyName?.trim(),
    ].whereType<String>().where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  @visibleForTesting
  static String normalizedAppleWebServiceId(String? serviceId) {
    return serviceId?.trim() ?? '';
  }

  @visibleForTesting
  static bool appleSignInAvailableForPlatform({
    required bool isWeb,
    required TargetPlatform platform,
    required String? webServiceId,
  }) {
    if (isWeb) {
      return normalizedAppleWebServiceId(webServiceId).isNotEmpty;
    }

    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  static bool get appleSignInAvailable => appleSignInAvailableForPlatform(
    isWeb: kIsWeb,
    platform: defaultTargetPlatform,
    webServiceId: _appleWebServiceId,
  );

  /// Launches Apple Sign-In and returns the identity token on success.
  /// On web, requires a configured service ID and redirect URI in Apple
  /// Developer Console. Uses native AuthenticationServices on iOS/macOS.
  /// Throws [SignInWithAppleAuthorizationException] on cancellation.
  static Future<AppleSignInResult> launchAppleSignIn() async {
    final webServiceId = normalizedAppleWebServiceId(_appleWebServiceId);
    if (!appleSignInAvailable) {
      throw const AppleSignInUnavailableException();
    }

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      webAuthenticationOptions: kIsWeb
          ? WebAuthenticationOptions(
              clientId: webServiceId,
              redirectUri: Uri.parse('${Uri.base.origin}$_appleCallbackPath'),
            )
          : null,
    );

    final identityToken = credential.identityToken;
    if (identityToken == null) {
      throw Exception('Failed to get Apple identity token.');
    }
    return AppleSignInResult(
      identityToken: identityToken,
      displayName: appleDisplayNameFromParts(
        givenName: credential.givenName,
        familyName: credential.familyName,
      ),
    );
  }

  /// Returns a user-friendly error message for OAuth failures.
  /// In debug mode, includes the original error for easier diagnosis.
  static AppFailure toFailure(Object error) {
    if (error is AppleSignInUnavailableException) {
      return const LocalizedFailure(AppFailureMessageKey.authAppleUnavailable);
    }
    if (isCancellationError(error)) {
      return const LocalizedFailure(AppFailureMessageKey.authSignInCancelled);
    }
    final apiFailure = ApiError.toFailure(error);
    if (apiFailure is! UnknownFailure) {
      return apiFailure;
    }
    return const LocalizedFailure(AppFailureMessageKey.authErrorGeneric);
  }

  static String friendlyError(Object error) {
    final l10n = currentAppLocalizations();
    final failure = toFailure(error);
    if (kDebugMode &&
        failure is LocalizedFailure &&
        failure.key == AppFailureMessageKey.authErrorGeneric) {
      return '${l10n.authErrorDebugPrefix}: $error';
    }
    return failure.userMessage(l10n);
  }

  static bool isCancellationError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('cancel') || message.contains('closed');
  }
}
