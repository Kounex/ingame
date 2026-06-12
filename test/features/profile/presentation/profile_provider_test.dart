import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
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

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  Future<AuthState> build() async => _initialState;

  void setAuthState(AuthState nextState) {
    state = AsyncValue.data(nextState);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  test('loads profile when authenticated', () async {
    const user = User(
      id: 'user-1',
      displayName: 'First User',
      timezone: 'UTC',
    );
    final repository = _FakeProfileRepository(initialUser: user);

    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repository),
        authNotifierProvider.overrideWith(
          () => _FakeAuthNotifier(AuthState.authenticated(user)),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Force the auth provider to settle first.
    await container.read(authNotifierProvider.future);

    final profile = await container.read(profileNotifierProvider.future);
    expect(profile?.displayName, 'First User');
  });

  test('returns null when not authenticated', () async {
    final repository = _FakeProfileRepository(
      initialUser: const User(
        id: 'user-1',
        displayName: 'Test',
        timezone: 'UTC',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repository),
        authNotifierProvider.overrideWith(
          () => _FakeAuthNotifier(const AuthState.unauthenticated()),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.future);

    final profile = await container.read(profileNotifierProvider.future);
    expect(profile, isNull);
  });

  test('auth state change triggers profile reload', () async {
    const user1 = User(
      id: 'user-1',
      displayName: 'First User',
      timezone: 'UTC',
    );
    const user2 = User(
      id: 'user-2',
      displayName: 'Second User',
      timezone: 'UTC',
    );
    final repository = _FakeProfileRepository(initialUser: user1);
    late _FakeAuthNotifier authNotifier;

    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repository),
        authNotifierProvider.overrideWith(() {
          authNotifier = _FakeAuthNotifier(AuthState.authenticated(user1));
          return authNotifier;
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.future);
    final initialProfile = await container.read(profileNotifierProvider.future);
    expect(initialProfile?.displayName, 'First User');

    repository.setUser(user2);
    authNotifier.setAuthState(AuthState.authenticated(user2));

    // Allow the provider graph to settle after auth state change.
    await Future<void>.delayed(Duration.zero);

    final refreshedProfile = await container.read(profileNotifierProvider.future);
    expect(refreshedProfile?.displayName, 'Second User');
  });
}
