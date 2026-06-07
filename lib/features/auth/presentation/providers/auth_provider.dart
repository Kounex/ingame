import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/networking/api_error.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/auth_repository.dart';
import '../../data/oauth_launcher.dart';
import '../../domain/auth_state.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    ref.watch(authInvalidationSignalProvider);
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getAccessToken();

    if (token == null) {
      return const AuthState.unauthenticated();
    }

    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.getCurrentUser();
      return AuthState.authenticated(user);
    } catch (_) {
      await storage.clearTokens();
      return const AuthState.unauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.data(AuthState.loading());
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.login(email: email, password: password);
      state = AsyncValue.data(AuthState.authenticated(user));
    } catch (e) {
      state = AsyncValue.data(AuthState.error(ApiError.toFailure(e)));
    }
  }

  void clearError() {
    final current = state.asData?.value;
    if (current?.maybeWhen(error: (_) => true, orElse: () => false) ?? false) {
      state = const AsyncValue.data(AuthState.unauthenticated());
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.data(AuthState.loading());
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = AsyncValue.data(AuthState.authenticated(user));
    } catch (e) {
      state = AsyncValue.data(AuthState.error(ApiError.toFailure(e)));
    }
  }

  Future<void> steamLogin(Map<String, String> params) async {
    state = const AsyncValue.data(AuthState.loading());
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.steamAuth(params);
      state = AsyncValue.data(AuthState.authenticated(user));
    } catch (e) {
      state = AsyncValue.data(AuthState.error(ApiError.toFailure(e)));
    }
  }

  Future<void> discordLogin() async {
    state = const AsyncValue.data(AuthState.loading());
    DiscordAuthResult? discordAuthResult;
    try {
      discordAuthResult = await OAuthLauncher.launchDiscordAuth();
    } catch (e) {
      if (OAuthLauncher.isCancellationError(e)) {
        state = const AsyncValue.data(AuthState.unauthenticated());
        return;
      }
      state = AsyncValue.data(AuthState.error(OAuthLauncher.toFailure(e)));
      return;
    }

    await completeDiscordLogin(discordAuthResult);
  }

  Future<void> completeDiscordLogin(DiscordAuthResult discordAuthResult) async {
    state = const AsyncValue.data(AuthState.loading());
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.discordAuth(
        code: discordAuthResult.code,
        codeVerifier: discordAuthResult.codeVerifier,
        redirectUri: discordAuthResult.redirectUri,
      );
      state = AsyncValue.data(AuthState.authenticated(user));
    } catch (e) {
      state = AsyncValue.data(AuthState.error(ApiError.toFailure(e)));
    }
  }

  Future<void> appleLogin() async {
    state = const AsyncValue.data(AuthState.loading());
    AppleSignInResult? appleSignInResult;
    try {
      appleSignInResult = await OAuthLauncher.launchAppleSignIn();
    } catch (e) {
      if (OAuthLauncher.isCancellationError(e)) {
        state = const AsyncValue.data(AuthState.unauthenticated());
        return;
      }
      state = AsyncValue.data(AuthState.error(OAuthLauncher.toFailure(e)));
      return;
    }

    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.appleAuth(
        appleSignInResult.identityToken,
        displayName: appleSignInResult.displayName,
      );
      state = AsyncValue.data(AuthState.authenticated(user));
    } catch (e) {
      state = AsyncValue.data(AuthState.error(ApiError.toFailure(e)));
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    ref.read(logoutRedirectPendingProvider.notifier).state = true;
    state = const AsyncValue.data(AuthState.unauthenticated());
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
