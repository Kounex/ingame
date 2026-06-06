import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/auth/auth_session.dart';
import 'package:ingame/core/routing/app_router.dart';
import 'package:ingame/core/routing/route_names.dart';
import 'package:ingame/core/storage/preferences.dart';
import 'package:ingame/features/auth/presentation/screens/login_screen.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/features/groups/data/groups_repository.dart';
import 'package:ingame/features/groups/domain/group_model.dart';
import 'package:ingame/features/groups/domain/membership_model.dart';
import 'package:ingame/features/groups/presentation/providers/groups_provider.dart';
import 'package:ingame/features/groups/presentation/providers/group_coordination_provider.dart';
import 'package:ingame/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:ingame/features/profile/presentation/providers/profile_provider.dart';
import 'package:ingame/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
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

  final Group _group = const Group(
    id: 'group-1',
    name: 'Raid Night',
    description: 'Preview group',
    inviteCode: 'ABC123',
    isDiscoverable: false,
    joinMode: 'open',
    createdBy: 'owner-1',
    memberCount: 3,
  );

  @override
  Future<List<Group>> listMyGroups() async => [_group];

  @override
  Future<Group> getGroup(String id) async => _group;

  @override
  Future<List<GroupMember>> listMembers(String groupId) async => const [
    GroupMember(
      id: 'membership-1',
      userId: 'user-1',
      displayName: 'Ready Player',
      role: 'owner',
    ),
  ];

  @override
  Future<List<JoinRequest>> listJoinRequests(String groupId) async => const [];

  @override
  Future<Group> previewByInviteCode(String code) async {
    return _group.copyWith(inviteCode: code);
  }

  @override
  Future<Group> joinByInviteCode(String code) async {
    return _group.copyWith(inviteCode: code, memberCount: 4);
  }
}

class _FakeGroupsNotifier extends GroupsNotifier {
  @override
  Future<List<Group>> build() async => const [
    Group(
      id: 'group-1',
      name: 'Raid Night',
      description: 'Preview group',
      inviteCode: 'ABC123',
      isDiscoverable: false,
      joinMode: 'open',
      createdBy: 'owner-1',
      memberCount: 3,
    ),
  ];
}

class _FakeGroupCoordinationNotifier extends GroupCoordinationNotifier {
  _FakeGroupCoordinationNotifier() : super('group-1');

  @override
  Future<GroupCoordinationState> build() async =>
      const GroupCoordinationState();
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
  test('shell branch root routes use page builders', () {
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _FakeAuthNotifier(const AuthState.unauthenticated()),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    final routes = router.configuration.routes;
    final shellRoute = routes.whereType<StatefulShellRoute>().single;
    final branchRoots = shellRoute.branches
        .expand((branch) => branch.routes)
        .whereType<GoRoute>()
        .where(
          (route) =>
              route.path == RoutePaths.home ||
              route.path == RoutePaths.discover ||
              route.path == RoutePaths.profile,
        )
        .toList();

    expect(branchRoots, hasLength(3));
    expect(branchRoots.every((route) => route.pageBuilder != null), isTrue);
  });

  testWidgets(
    'protected profile route stays behind login while auth is still resolving',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(const AuthState.loading()),
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/login?from=%2Fprofile',
      );
    },
  );

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

  testWidgets(
    'onboarding route stays put while auth is refreshing before completion redirect',
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

      authNotifier.setAuthState(const AuthState.loading());
      await tester.pump();

      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/onboarding?from=%2Fjoin%2FABC123',
      );

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
    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.text('Logout').last);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.toString(), '/login');

    final _ = authNotifier;
  });

  testWidgets(
    'iOS shell tabs and pushed group routes remain navigable',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(AuthState.authenticated(_completedUser())),
          ),
          profileNotifierProvider.overrideWith(
            () => _FakeProfileNotifier(_completedUser()),
          ),
          groupsRepositoryProvider.overrideWithValue(_FakeGroupsRepository()),
          groupsNotifierProvider.overrideWith(_FakeGroupsNotifier.new),
          groupCoordinationNotifierProvider(
            'group-1',
          ).overrideWith(_FakeGroupCoordinationNotifier.new),
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
      await tester.pumpAndSettle();

      expect(find.text('My Groups'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.toString(), '/profile');
      expect(find.text('Logout'), findsOneWidget);

      await tester.tap(find.text('Groups'));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.toString(), '/');
      expect(find.text('Raid Night'), findsOneWidget);

      await tester.tap(find.text('Raid Night'));
      await tester.pumpAndSettle();

      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/groups/group-1',
      );
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS}),
  );
}
