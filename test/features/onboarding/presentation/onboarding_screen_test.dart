import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/storage/secure_storage.dart';
import 'package:ingame/features/auth/data/auth_repository.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:ingame/features/profile/presentation/providers/profile_provider.dart';
import 'package:ingame/l10n/app_localizations.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  Future<AuthState> build() async => _initialState;
}

class _RecordingProfileNotifier extends ProfileNotifier {
  int updateCalls = 0;
  Map<String, dynamic>? lastUpdates;

  @override
  Future<User?> build() async => null;

  @override
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    updateCalls++;
    lastUpdates = updates;
    state = const AsyncValue.data(null);
  }
}

class _FakeSecureStorageService implements SecureStorageService {
  @override
  Future<void> clearTokens() async {}

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({required this.emailAvailable})
    : super(dio: Dio(), storage: _FakeSecureStorageService());

  final bool emailAvailable;

  @override
  Future<bool> checkEmailAvailable(String email) async => emailAvailable;
}

Future<void> pumpOnboardingScreen(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  AuthState authState = const AuthState.authenticated(
    User(id: 'user-1', displayName: 'Ready Player', timezone: 'UTC'),
  ),
  ProfileNotifier? profileNotifier,
  AuthRepository? authRepository,
}) async {
  final notifier = profileNotifier ?? _RecordingProfileNotifier();
  final fakeAuthRepository =
      authRepository ?? _FakeAuthRepository(emailAvailable: true);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => _FakeAuthNotifier(authState)),
        profileNotifierProvider.overrideWith(() => notifier),
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
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

Future<void> _tapVisibleButton(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.text(label),
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('onboarding welcome page shows localized copy', (tester) async {
    await pumpOnboardingScreen(tester, locale: const Locale('de'));
    await tester.pumpAndSettle();

    expect(find.text('Willkommen bei InGame'), findsOneWidget);
    expect(find.text('Gaming-Präferenzen'), findsNothing);
  });

  testWidgets('onboarding welcome page uses the canonical logo asset', (
    tester,
  ) async {
    await pumpOnboardingScreen(tester);
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(find.byType(Image).first);

    expect(image.image, isA<AssetImage>());
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/ingame-logo.png',
    );
    expect(find.byIcon(Icons.sports_esports), findsNothing);
  });

  testWidgets('onboarding keeps the welcome CTA constrained on desktop', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 1200);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpOnboardingScreen(tester);
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.widgetWithText(ElevatedButton, 'Get Started')).width,
      lessThan(700),
    );
  });

  testWidgets('finish can succeed without selecting a gaming time slot', (
    tester,
  ) async {
    final profileNotifier = _RecordingProfileNotifier();

    await pumpOnboardingScreen(tester, profileNotifier: profileNotifier);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Ready Player');
    await tester.enterText(find.byType(TextFormField).at(1), 'ready@test.com');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    await _tapVisibleButton(tester, 'Next');

    expect(find.text('Gaming Preferences'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Finish'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Finish'));
    await tester.pump();

    expect(profileNotifier.updateCalls, 1);
    expect(
      profileNotifier.lastUpdates?.containsKey('preferred_gaming_hours'),
      isFalse,
    );
  });

  testWidgets('onboarding saves the selected timezone', (tester) async {
    final profileNotifier = _RecordingProfileNotifier();

    await pumpOnboardingScreen(tester, profileNotifier: profileNotifier);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Ready Player');
    await tester.enterText(find.byType(TextFormField).at(1), 'ready@test.com');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    await tester.scrollUntilVisible(
      find.text('Timezone'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Timezone'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('timezone-selector-trigger')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('timezone-option-Europe/Berlin')));
    await tester.pumpAndSettle();

    await _tapVisibleButton(tester, 'Next');
    await tester.scrollUntilVisible(
      find.text('Finish'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Finish'));
    await tester.pump();

    expect(profileNotifier.lastUpdates?['timezone'], 'Europe/Berlin');
  });

  testWidgets('finish does not throw after navigating away from profile step', (
    tester,
  ) async {
    final profileNotifier = _RecordingProfileNotifier();

    await pumpOnboardingScreen(tester, profileNotifier: profileNotifier);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Ready Player');
    await tester.enterText(find.byType(TextFormField).at(1), 'ready@test.com');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    await _tapVisibleButton(tester, 'Next');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Finish'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Finish'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(profileNotifier.updateCalls, 1);
  });

  testWidgets(
    'onboarding saves selected preset slots for only the chosen day',
    (tester) async {
      final profileNotifier = _RecordingProfileNotifier();

      await pumpOnboardingScreen(tester, profileNotifier: profileNotifier);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Ready Player');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'ready@test.com',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      await _tapVisibleButton(tester, 'Next');

      await tester.tap(
        find.byKey(const Key('weekly-availability-chip-monday-morning')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('weekly-availability-chip-monday-evening')),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Finish'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish'));
      await tester.pump();

      expect(profileNotifier.lastUpdates?['preferred_gaming_hours'], {
        'monday': [
          {'start': '06:00', 'end': '12:00'},
          {'start': '18:00', 'end': '00:00'},
        ],
      });
    },
  );

  testWidgets('onboarding all day preset expands to the full day schedule', (
    tester,
  ) async {
    final profileNotifier = _RecordingProfileNotifier();

    await pumpOnboardingScreen(tester, profileNotifier: profileNotifier);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Ready Player');
    await tester.enterText(find.byType(TextFormField).at(1), 'ready@test.com');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    await _tapVisibleButton(tester, 'Next');

    await tester.scrollUntilVisible(
      find.byKey(const Key('weekly-availability-chip-saturday-all-day')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(
      find.byKey(const Key('weekly-availability-chip-saturday-all-day')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Finish'));
    await tester.pump();

    expect(profileNotifier.lastUpdates?['preferred_gaming_hours'], {
      'saturday': [
        {'start': '06:00', 'end': '12:00'},
        {'start': '12:00', 'end': '18:00'},
        {'start': '18:00', 'end': '00:00'},
        {'start': '00:00', 'end': '06:00'},
      ],
    });
  });

  testWidgets(
    'profile step shows a prefilled email field when auth already provides one',
    (tester) async {
      await pumpOnboardingScreen(
        tester,
        authState: const AuthState.authenticated(
          User(
            id: 'user-1',
            displayName: 'Apple Player',
            email: 'apple@test.com',
            timezone: 'UTC',
          ),
        ),
      );

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      final emailFields = tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      );
      expect(
        emailFields.any((field) => field.controller?.text == 'apple@test.com'),
        isTrue,
      );
    },
  );

  testWidgets('profile step requires an email before continuing onboarding', (
    tester,
  ) async {
    await pumpOnboardingScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Ready Player');
    await tester.pumpAndSettle();

    await _tapVisibleButton(tester, 'Next');

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Gaming Preferences'), findsNothing);
  });

  testWidgets(
    'gaming preferences step hides the Steam CTA when Steam is already linked',
    (tester) async {
      await pumpOnboardingScreen(
        tester,
        authState: const AuthState.authenticated(
          User(
            id: 'user-1',
            displayName: 'Steam Player',
            email: 'steam@test.com',
            timezone: 'UTC',
            steamId: 'steam-123',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      await _tapVisibleButton(tester, 'Next');

      expect(find.text('Gaming Preferences'), findsOneWidget);
      expect(find.text('Connect Steam'), findsNothing);
    },
  );
}
