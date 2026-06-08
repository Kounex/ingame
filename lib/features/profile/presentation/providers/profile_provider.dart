import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../auth/domain/user_model.dart';
import '../../data/profile_repository.dart';

class ProfileNotifier extends AsyncNotifier<User?> {
  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  @override
  Future<User?> build() async {
    ref.watch(sessionResetSignalProvider);
    try {
      return await _repo.getProfile();
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    final previousUser = state.asData?.value;
    if (previousUser == null) {
      state = const AsyncValue.loading();
    }

    try {
      state = AsyncValue.data(await _repo.getProfile());
    } catch (error, stackTrace) {
      if (previousUser == null) {
        state = AsyncValue.error(error, stackTrace);
      } else {
        state = AsyncValue.data(previousUser);
      }
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    await _replaceState((repo) => repo.updateProfile(updates));
  }

  Future<void> linkSteam(Map<String, String> openidParams) async {
    await _replaceState((repo) => repo.linkSteam(openidParams));
  }

  Future<void> unlinkSteam() async {
    await _replaceState((repo) => repo.unlinkSteam());
  }

  Future<void> linkDiscord({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    await _replaceState(
      (repo) => repo.linkDiscord(
        code: code,
        codeVerifier: codeVerifier,
        redirectUri: redirectUri,
      ),
    );
  }

  Future<void> unlinkDiscord() async {
    await _replaceState((repo) => repo.unlinkDiscord());
  }

  Future<void> linkApple(String identityToken) async {
    await _replaceState((repo) => repo.linkApple(identityToken));
  }

  Future<void> unlinkApple() async {
    await _replaceState((repo) => repo.unlinkApple());
  }

  Future<void> setEmailPassword({
    required String email,
    required String password,
  }) async {
    await _replaceState(
      (repo) => repo.setEmailPassword(email: email, password: password),
    );
  }

  Future<void> upsertManualSocialIdentity({
    required String provider,
    String? externalId,
    String? username,
    String? displayName,
    String? profileUrl,
  }) async {
    await _replaceState(
      (repo) => repo.upsertManualSocialIdentity(
        provider: provider,
        externalId: externalId,
        username: username,
        displayName: displayName,
        profileUrl: profileUrl,
      ),
    );
  }

  Future<void> deleteManualSocialIdentity(String provider) async {
    await _replaceState((repo) => repo.deleteManualSocialIdentity(provider));
  }

  Future<void> _replaceState(
    Future<User> Function(ProfileRepository repo) mutation,
  ) async {
    state = AsyncValue.data(await mutation(_repo));
  }
}

final profileNotifierProvider = AsyncNotifierProvider<ProfileNotifier, User?>(
  ProfileNotifier.new,
);

final profileUserProvider = Provider<User?>((ref) {
  return ref.watch(
    profileNotifierProvider.select((state) => state.asData?.value),
  );
});
