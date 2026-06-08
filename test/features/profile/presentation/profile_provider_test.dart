import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/auth/auth_session.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/profile/data/profile_repository.dart';
import 'package:ingame/features/profile/presentation/providers/profile_provider.dart';

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository({required User initialUser})
    : _user = initialUser,
      super(dio: Dio());

  User _user;

  void setUser(User nextUser) {
    _user = nextUser;
  }

  @override
  Future<User> getProfile() async => _user;
}

void main() {
  test('session reset reloads cached profile data for the next session', () async {
    final repository = _FakeProfileRepository(
      initialUser: const User(
        id: 'user-1',
        displayName: 'First User',
        timezone: 'UTC',
      ),
    );
    final container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final initialProfile = await container.read(profileNotifierProvider.future);
    expect(initialProfile?.displayName, 'First User');

    repository.setUser(
      const User(id: 'user-2', displayName: 'Second User', timezone: 'UTC'),
    );
    container.read(sessionResetSignalProvider.notifier).state++;

    final refreshedProfile = await container.read(profileNotifierProvider.future);
    expect(refreshedProfile?.displayName, 'Second User');
  });
}
