import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/auth/auth_session.dart';
import 'package:ingame/core/routing/app_router.dart';
import 'package:ingame/core/storage/preferences.dart';
import 'package:ingame/features/auth/presentation/screens/login_screen.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/features/groups/data/groups_repository.dart';
import 'package:ingame/features/groups/domain/group_model.dart';
import 'package:ingame/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:ingame/features/profile/presentation/providers/profile_provider.dart';
import 'package:ingame/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  Future<AuthState> build() async => _initialState;

  void setAuthState(AuthState nextState) {
    state = AsyncValue.data(nextState);
  }

  @override
  Future<void> logout() async {
    ref.read(logoutRedirectPendingProvider.notifier).state = true;
    state = const AsyncValue.data(AuthState.unauthenticated());
  }
}

class _FakeProfileNotifier extends ProfileNotifier {
  _FakeProfileNotifier(this._user);

  final User _user;

  @override
  Future<User?> build() async => _user;
}

class _FakeGroupsRepository extends GroupsRepository {
  _FakeGroupsRepository() : super(dio: Dio());

  @override
  Future<Group> previewByInviteCode(String code) async {
    return Group(
      id: 'group-1',
      name: 'Raid Night',
      description: 'Preview group',
      inviteCode: code,
      isDiscoverable: false,
      joinMode: 'open',
      createdBy: 'owner-1',
      memberCount: 3,
    );
  }

  @override
  Future<Group> joinByInviteCode(String code) async {
    return Group(
      id: 'group-1',
      name: 'Raid Night',
      description: 'Joined group',
      inviteCode: code,
      isDiscoverable: false,
      joinMode: 'open',
      createdBy: 'owner-1',
      memberCount: 4,
    );
  }
}

User _userMissingOnboardingData() =>
    const User(id: 'user-1', displayName: 'New Player', timezone: 'UTC');

User _completedUser() => const User(
  id: 'user-1',
  displayName: 'Ready Player',
  email: 'ready@test.com',
  bio: 'InGame player',
  timezone: 'UTC',
);

void main() {
  testWidgets(
    'unauthenticated redirect strips stray query params from preserved target',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(const AuthState.unauthenticated()),
          ),
          preferencesProvider.overrideWithValue(PreferencesService(prefs)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );

      router.go('/discover?debug=true');
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/login?from=%2Fdiscover',
      );
    },
  );

  testWidgets('join link redirect to onboarding preserves return target', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    late _FakeAuthNotifier authNotifier;
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => authNotifier = _FakeAuthNotifier(
            AuthState.authenticated(_userMissingOnboardingData()),
          ),
        ),
        groupsRepositoryProvider.overrideWithValue(_FakeGroupsRepository()),
        preferencesProvider.overrideWithValue(PreferencesService(prefs)),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );

    router.go('/join/ABC123');
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/onboarding?from=%2Fjoin%2FABC123',
    );

    // ignore: unused_local_variable
    final _ = authNotifier;
  });

  testWidgets(
    'onboarding route redirects to preserved target once onboarding is complete',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      late _FakeAuthNotifier authNotifier;
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => authNotifier = _FakeAuthNotifier(
              AuthState.authenticated(_userMissingOnboardingData()),
            ),
          ),
          groupsRepositoryProvider.overrideWithValue(_FakeGroupsRepository()),
          preferencesProvider.overrideWithValue(PreferencesService(prefs)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );

      router.go('/onboarding?from=%2Fjoin%2FABC123');
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);

      authNotifier.setAuthState(AuthState.authenticated(_completedUser()));
      await tester.pumpAndSettle();

      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/join/ABC123',
      );
    },
  );

  testWidgets('authenticated user without recovery email stays in onboarding', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _FakeAuthNotifier(
            const AuthState.authenticated(
              User(
                id: 'user-1',
                displayName: 'Steam Player',
                bio: 'Bio set',
                timezone: 'UTC',
                preferredGamingHours: {
                  'monday': [
                    {'start': '18:00', 'end': '22:00'},
                  ],
                },
              ),
            ),
          ),
        ),
        preferencesProvider.overrideWithValue(PreferencesService(prefs)),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );

    router.go('/');
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/onboarding?from=%2F',
    );
  });

  testWidgets('intentional logout from profile lands on clean login route', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    late _FakeAuthNotifier authNotifier;
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => authNotifier = _FakeAuthNotifier(
            AuthState.authenticated(_completedUser()),
          ),
        ),
        profileNotifierProvider.overrideWith(
          () => _FakeProfileNotifier(_completedUser()),
        ),
        preferencesProvider.overrideWithValue(PreferencesService(prefs)),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );

    router.go('/profile');
    await tester.pumpAndSettle();

    expect(find.text('Logout'), findsOneWidget);
    await tester.ensureVisible(find.text('Logout'));
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.toString(), '/login');

    final _ = authNotifier;
  });
}
