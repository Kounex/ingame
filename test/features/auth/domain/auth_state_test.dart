import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/user_model.dart';

void main() {
  test('maybeWhen matches authenticated state and falls back otherwise', () {
    const authenticated = AuthState.authenticated(
      User(
        id: 'user-1',
        displayName: 'Ready Player',
        timezone: 'UTC',
      ),
    );
    const unauthenticated = AuthState.unauthenticated();

    expect(
      authenticated.maybeWhen(
        authenticated: (user) => user.displayName,
        orElse: () => 'fallback',
      ),
      'Ready Player',
    );
    expect(
      unauthenticated.maybeWhen(
        authenticated: (user) => user.displayName,
        orElse: () => 'fallback',
      ),
      'fallback',
    );
  });
}
