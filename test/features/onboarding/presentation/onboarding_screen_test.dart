import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:ingame/features/profile/presentation/providers/profile_provider.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  Future<AuthState> build() async => _initialState;
}

class _RecordingProfileNotifier extends ProfileNotifier {
  int updateCalls = 0;

  @override
  Future<User?> build() async => null;

  @override
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    updateCalls++;
    state = const AsyncValue.data(null);
  }
}

void main() {
  testWidgets(
    'finish requires at least one gaming time slot',
    (tester) async {
      final profileNotifier = _RecordingProfileNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(
                const AuthState.authenticated(
                  User(
                    id: 'user-1',
                    displayName: 'Ready Player',
                    timezone: 'UTC',
                  ),
                ),
              ),
            ),
            profileNotifierProvider.overrideWith(
              () => profileNotifier,
            ),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Ready Player');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Gaming Preferences'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Finish'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Finish'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(profileNotifier.updateCalls, 0);
      expect(
        find.text('Select at least one time slot to complete onboarding.'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 5));
    },
  );
}
