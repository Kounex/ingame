import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ingame/core/localization/locale_controller.dart';
import 'package:ingame/core/storage/preferences.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/features/profile/data/profile_repository.dart';
import 'package:ingame/features/profile/presentation/screens/profile_screen.dart';
import 'package:ingame/l10n/app_localizations.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  Future<AuthState> build() async => _initialState;
}

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository(this._user) : super(dio: Dio());

  User _user;
  int unlinkSteamCalls = 0;

  @override
  Future<User> getProfile() async => _user;

  @override
  Future<User> unlinkSteam() async {
    unlinkSteamCalls++;
    _user = _user.copyWith(steamId: null);
    return _user;
  }
}

class _ProfileHarness extends ConsumerWidget {
  const _ProfileHarness({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeControllerProvider);

    return MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );
  }
}

Finder _accountRow(String label) {
  return find.ancestor(of: find.text(label), matching: find.byType(InkWell));
}

Future<void> _scrollToAccountRow(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.text(label),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  Future<void> pumpProfile(
    WidgetTester tester, {
    required _FakeProfileRepository repository,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(PreferencesService(prefs)),
          profileRepositoryProvider.overrideWithValue(repository),
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(
              const AuthState.authenticated(
                User(id: 'auth-user', displayName: 'Tester', timezone: 'UTC'),
              ),
            ),
          ),
        ],
        child: const _ProfileHarness(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'connected Steam row advertises disconnect and shows destructive dialog copy',
    (tester) async {
      final repository = _FakeProfileRepository(
        const User(
          id: 'user-1',
          displayName: 'Steam User',
          email: 'steam@test.com',
          hasPasswordLogin: true,
          steamId: 'steam-123',
          timezone: 'UTC',
        ),
      );

      await pumpProfile(tester, repository: repository);
      await _scrollToAccountRow(tester, 'Steam');

      expect(find.text('Connected. Tap to disconnect.'), findsOneWidget);

      await tester.tap(_accountRow('Steam'));
      await tester.pumpAndSettle();

      expect(find.text('Disconnect Steam?'), findsOneWidget);
      expect(
        find.text('You won\'t be able to sign in with Steam after this.'),
        findsOneWidget,
      );
      expect(
        find.text('Your current session will stay active on this device.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Steam-connected features will stay unavailable until you relink Steam.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Make sure another sign-in method is already connected before you continue.',
        ),
        findsOneWidget,
      );
      expect(find.text('Disconnect'), findsOneWidget);
    },
  );

  testWidgets('successful Steam unlink shows success feedback', (tester) async {
    final repository = _FakeProfileRepository(
      const User(
        id: 'user-1',
        displayName: 'Steam User',
        email: 'steam@test.com',
        hasPasswordLogin: true,
        steamId: 'steam-123',
        timezone: 'UTC',
      ),
    );

    await pumpProfile(tester, repository: repository);
    await _scrollToAccountRow(tester, 'Steam');

    await tester.tap(_accountRow('Steam'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();

    expect(repository.unlinkSteamCalls, 1);
    expect(find.text('Steam disconnected.'), findsOneWidget);

    final steamRow = _accountRow('Steam');
    expect(
      find.descendant(of: steamRow, matching: find.text('Not connected')),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('gaming hours card collapses the full preset set into all day', (
    tester,
  ) async {
    final repository = _FakeProfileRepository(
      const User(
        id: 'user-1',
        displayName: 'Schedule User',
        timezone: 'UTC',
        preferredGamingHours: {
          'monday': [
            {'start': '06:00', 'end': '12:00'},
            {'start': '12:00', 'end': '18:00'},
            {'start': '18:00', 'end': '00:00'},
            {'start': '00:00', 'end': '06:00'},
          ],
        },
      ),
    );

    await pumpProfile(tester, repository: repository);
    await tester.scrollUntilVisible(
      find.text('GAMING HOURS'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('All day'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
  });

  testWidgets(
    'last remaining login method shows explicit guidance instead of disconnect flow',
    (tester) async {
      final repository = _FakeProfileRepository(
        const User(
          id: 'user-1',
          displayName: 'Steam Only',
          steamId: 'steam-123',
          timezone: 'UTC',
        ),
      );

      await pumpProfile(tester, repository: repository);
      await _scrollToAccountRow(tester, 'Steam');

      await tester.tap(_accountRow('Steam'));
      await tester.pumpAndSettle();

      expect(
        find.text('Add another sign-in method before disconnecting this one.'),
        findsOneWidget,
      );
      expect(find.text('Disconnect Steam?'), findsNothing);
      expect(repository.unlinkSteamCalls, 0);

      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    },
  );
}
