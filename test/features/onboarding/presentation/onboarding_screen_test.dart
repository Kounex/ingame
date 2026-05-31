import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/l10n/app_localizations.dart';
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

Future<void> pumpOnboardingScreen(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  AuthState authState = const AuthState.authenticated(
    User(
      id: 'user-1',
      displayName: 'Ready Player',
      timezone: 'UTC',
    ),
  ),
  ProfileNotifier? profileNotifier,
}) async {
  final notifier = profileNotifier ?? _RecordingProfileNotifier();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _FakeAuthNotifier(authState),
        ),
        profileNotifierProvider.overrideWith(
          () => notifier,
        ),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const OnboardingScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('onboarding welcome page shows localized copy', (tester) async {
    await pumpOnboardingScreen(tester, locale: const Locale('de'));
    await tester.pumpAndSettle();

    expect(find.text('Willkommen bei InGame'), findsOneWidget);
    expect(find.text('Gaming-Präferenzen'), findsNothing);
  });

  testWidgets(
    'finish requires at least one gaming time slot',
    (tester) async {
      final profileNotifier = _RecordingProfileNotifier();

      await pumpOnboardingScreen(tester, profileNotifier: profileNotifier);

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
