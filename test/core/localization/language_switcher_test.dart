import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'package:ingame/core/localization/locale_controller.dart';
import 'package:ingame/core/networking/app_failure.dart';
import 'package:ingame/core/storage/secure_storage.dart';
import 'package:ingame/core/storage/preferences.dart';
import 'package:ingame/features/auth/data/auth_repository.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/features/auth/presentation/screens/login_screen.dart';
import 'package:ingame/features/auth/presentation/screens/register_screen.dart';
import 'package:ingame/features/profile/presentation/providers/profile_provider.dart';
import 'package:ingame/features/profile/presentation/screens/profile_screen.dart';
import 'package:ingame/l10n/app_localizations.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  Future<AuthState> build() async => _initialState;
}

class _FakeSecureStorage implements SecureStorageService {
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

class _CountingAuthRepository extends AuthRepository {
  _CountingAuthRepository({
    required this.emailAvailable,
    required this.displayNameAvailable,
  }) : super(dio: Dio(), storage: _FakeSecureStorage());

  final bool emailAvailable;
  final bool displayNameAvailable;
  int emailChecks = 0;
  int displayNameChecks = 0;

  @override
  Future<bool> checkEmailAvailable(String email) async {
    emailChecks++;
    return emailAvailable;
  }

  @override
  Future<bool> checkDisplayNameAvailable(String displayName) async {
    displayNameChecks++;
    return displayNameAvailable;
  }
}

class _FakeProfileNotifier extends ProfileNotifier {
  _FakeProfileNotifier(this.user);

  final User user;

  @override
  Future<User?> build() async => user;
}

class _LocaleHarness extends ConsumerWidget {
  const _LocaleHarness({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final resolvedLocale = ref.watch(resolvedLocaleProvider);
    intl.Intl.defaultLocale = resolvedLocale.toLanguageTag();

    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );
  }
}

User _profileUser() => const User(
  id: 'user-1',
  displayName: 'Ready Player',
  bio: 'InGame player',
  timezone: 'UTC',
  preferredGamingHours: {
    'monday': [
      {'start': '18:00', 'end': '22:00'},
    ],
  },
);

void main() {
  testWidgets('login language switcher updates copy and persists locale', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(PreferencesService(prefs)),
        ],
        child: const _LocaleHarness(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('language-switcher-compact-trigger')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch').last);
    await tester.pumpAndSettle();

    expect(find.text('E-Mail'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);
    expect(prefs.getString('locale_code'), 'de');
  });

  testWidgets('language switcher menu marks the active language', (tester) async {
    SharedPreferences.setMockInitialValues({'locale_code': 'de'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(PreferencesService(prefs)),
        ],
        child: const _LocaleHarness(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('language-switcher-compact-trigger')),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byKey(const ValueKey('language-option-de')), findsOneWidget);
  });

  testWidgets('login error banner re-localizes on language switch', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(PreferencesService(prefs)),
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(
              const AuthState.error(
                BackendFailure(
                  statusCode: 401,
                  detail: 'Invalid email or password',
                  code: 'auth.invalid_credentials',
                ),
              ),
            ),
          ),
        ],
        child: const _LocaleHarness(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Invalid credentials. Please try again.'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('language-switcher-compact-trigger')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Ungültige Anmeldedaten. Bitte versuche es erneut.'),
      findsOneWidget,
    );
  });

  testWidgets('login validator errors re-localize on language switch', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(PreferencesService(prefs)),
        ],
        child: const _LocaleHarness(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('language-switcher-compact-trigger')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch').last);
    await tester.pumpAndSettle();

    expect(find.text('E-Mail ist erforderlich'), findsOneWidget);
  });

  testWidgets(
    'register availability errors re-localize without repeating availability checks',
    (tester) async {
      tester.binding.platformDispatcher.localeTestValue = const Locale('en');
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final authRepository = _CountingAuthRepository(
        emailAvailable: false,
        displayNameAvailable: true,
      );
      final container = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(PreferencesService(prefs)),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const _LocaleHarness(home: RegisterScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(1),
        'taken@example.com',
      );
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(authRepository.emailChecks, 1);

      await tester.tap(find.text('Create Account').last);
      await tester.pumpAndSettle();

      expect(find.text('This email is already taken'), findsOneWidget);

      await container.read(localeControllerProvider.notifier).setLocale(
        const Locale('de'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Diese E-Mail ist bereits vergeben'), findsOneWidget);
      expect(authRepository.emailChecks, 1);
    },
  );

  testWidgets('profile language switcher reflects and updates shared locale', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'locale_code': 'de'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(PreferencesService(prefs)),
          profileNotifierProvider.overrideWith(
            () => _FakeProfileNotifier(_profileUser()),
          ),
        ],
        child: const _LocaleHarness(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Sprache'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('language-switcher-settings-trigger')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('language-switcher-settings-trigger')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(prefs.getString('locale_code'), 'en');
  });

  testWidgets(
    'profile shows email separately from password login state for Apple-only accounts',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const email = 'apple-only@test.com';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(PreferencesService(prefs)),
            profileNotifierProvider.overrideWith(
              () => _FakeProfileNotifier(
                const User(
                  id: 'user-apple-only',
                  displayName: 'Apple Only',
                  email: email,
                  appleId: 'apple-id-123',
                  timezone: 'UTC',
                ),
              ),
            ),
          ],
          child: const _LocaleHarness(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(email), findsOneWidget);

      final emailPasswordRow = find.ancestor(
        of: find.text('Email & Password'),
        matching: find.byType(InkWell),
      );

      expect(
        find.descendant(
          of: emailPasswordRow,
          matching: find.text('Not connected'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: emailPasswordRow, matching: find.text(email)),
        findsNothing,
      );
    },
  );
}
