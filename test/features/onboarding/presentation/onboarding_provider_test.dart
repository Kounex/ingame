import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/features/onboarding/presentation/providers/onboarding_provider.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  Future<AuthState> build() async => _initialState;
}

void main() {
  test(
    'needsOnboardingProvider ignores missing gaming hours once email and bio exist',
    () {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(
              const AuthState.authenticated(
                User(
                  id: 'user-1',
                  displayName: 'Ready Player',
                  email: 'ready@test.com',
                  bio: 'Bio set',
                  timezone: 'UTC',
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(needsOnboardingProvider), isFalse);
    },
  );
}
