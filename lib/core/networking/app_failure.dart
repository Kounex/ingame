import '../../l10n/app_localizations.dart';
import '../localization/locale_controller.dart';

enum AppFailureMessageKey {
  authAppleSignInFailed,
  authAppleUnavailable,
  authSignInCancelled,
  authErrorGeneric,
  registerEmailTaken,
  registerDisplayNameTaken,
}

enum AppNetworkFailureType { timeout, connection, unknown }

sealed class AppFailure {
  const AppFailure();

  String userMessage([AppLocalizations? l10n]) {
    final localizations = l10n ?? currentAppLocalizations();
    return switch (this) {
      BackendFailure() => _backendUserMessage(localizations),
      NetworkFailure() => _networkUserMessage(localizations),
      ValidationFailure(:final field, :final message) =>
        localizations.errorValidationFieldMessage(
          _humanizeField(field),
          message,
        ),
      LocalizedFailure() => _localizedUserMessage(localizations),
      UnknownFailure() => localizations.errorSomethingWentWrong,
    };
  }

  String _backendUserMessage(AppLocalizations l10n) {
    final failure = this as BackendFailure;
    return switch (failure.code) {
      'auth.invalid_credentials' => l10n.errorInvalidCredentials,
      'auth.email_taken' || 'user.email_taken' => l10n.registerEmailTaken,
      'auth.steam_profile_unavailable' => l10n.authErrorGeneric,
      'auth.steam_relink_required' => l10n.authSteamRelinkRequired,
      'auth.apple_relink_required' => l10n.authAppleRelinkRequired,
      'user.steam_account_already_linked' ||
      'user.apple_account_already_linked' ||
      'group.member_already_exists' ||
      'join_request.pending_already_exists' => l10n.errorAlreadyExists,
      'group.delete_requires_owner' ||
      'group.owner_required' ||
      'group.admin_or_owner_required' ||
      'join_request.admin_or_owner_required' => l10n.errorNoPermission,
      'group.owner_cannot_leave' => l10n.groupOwnerCannotLeave,
      'group.invite_code_invalid' ||
      'group.not_found' ||
      'join_request.not_found' ||
      'user.not_found' => l10n.errorNotFound,
      'auth.steam_openid_invalid' ||
      'auth.apple_token_invalid' ||
      'group.invalid_role_change' ||
      'group.transfer_invalid_target' ||
      'user.email_password_already_set' => l10n.errorCheckInput,
      'user.last_auth_method_required' => l10n.profileLastAuthMethodRequired,
      'user.avatar_upload_unavailable' => l10n.errorServer,
      'auth.missing_credentials' ||
      'auth.access_token_invalid' ||
      'auth.access_token_type_invalid' ||
      'auth.access_token_user_not_found' ||
      'auth.refresh_token_invalid' ||
      'auth.refresh_token_type_invalid' ||
      'auth.refresh_token_revoked' ||
      'auth.refresh_token_user_not_found' => l10n.authErrorGeneric,
      _ => failure.detail ?? _statusFallback(l10n, failure.statusCode),
    };
  }

  String _networkUserMessage(AppLocalizations l10n) {
    final failure = this as NetworkFailure;
    return switch (failure.type) {
      AppNetworkFailureType.timeout => l10n.errorConnectionTimedOut,
      AppNetworkFailureType.connection => l10n.errorCouldNotConnect,
      AppNetworkFailureType.unknown => l10n.errorNetwork,
    };
  }

  String _localizedUserMessage(AppLocalizations l10n) {
    final failure = this as LocalizedFailure;
    return switch (failure.key) {
      AppFailureMessageKey.authAppleSignInFailed => l10n.authAppleSignInFailed,
      AppFailureMessageKey.authAppleUnavailable => l10n.authAppleUnavailable,
      AppFailureMessageKey.authSignInCancelled => l10n.authSignInCancelled,
      AppFailureMessageKey.authErrorGeneric => l10n.authErrorGeneric,
      AppFailureMessageKey.registerEmailTaken => l10n.registerEmailTaken,
      AppFailureMessageKey.registerDisplayNameTaken =>
        l10n.registerDisplayNameTaken,
    };
  }

  String _statusFallback(AppLocalizations l10n, int? statusCode) {
    if (statusCode == null) {
      return l10n.errorSomethingWentWrong;
    }

    return switch (statusCode) {
      400 => l10n.errorInvalidRequest,
      401 => l10n.errorInvalidCredentials,
      403 => l10n.errorNoPermission,
      404 => l10n.errorNotFound,
      409 => l10n.errorAlreadyExists,
      422 => l10n.errorCheckInput,
      429 => l10n.errorTooManyRequests,
      >= 500 => l10n.errorServer,
      _ => l10n.errorUnknownWithCode(statusCode),
    };
  }

  String _humanizeField(String field) {
    return field
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'(^| )(\w)'),
          (m) => '${m[1]}${m[2]!.toUpperCase()}',
        )
        .trim();
  }
}

final class BackendFailure extends AppFailure {
  const BackendFailure({this.statusCode, this.detail, this.code});

  final int? statusCode;
  final String? detail;
  final String? code;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(this.type);

  final AppNetworkFailureType type;
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure({required this.field, required this.message});

  final String field;
  final String message;
}

final class LocalizedFailure extends AppFailure {
  const LocalizedFailure(this.key);

  final AppFailureMessageKey key;
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure();
}
