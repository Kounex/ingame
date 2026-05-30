import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/routing/app_router.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/features/groups/data/groups_repository.dart';
import 'package:ingame/features/groups/domain/group_model.dart';
import 'package:ingame/features/onboarding/presentation/screens/onboarding_screen.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  Future<AuthState> build() async => _initialState;

  void setAuthState(AuthState nextState) {
    state = AsyncValue.data(nextState);
  }
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

User _userMissingOnboardingData() => const User(
  id: 'user-1',
  displayName: 'New Player',
  timezone: 'UTC',
);

User _completedUser() => const User(
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
  testWidgets(
    'join link redirect to onboarding preserves return target',
    (tester) async {
      late _FakeAuthNotifier authNotifier;
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => authNotifier = _FakeAuthNotifier(
              AuthState.authenticated(_userMissingOnboardingData()),
            ),
          ),
          groupsRepositoryProvider.overrideWithValue(_FakeGroupsRepository()),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
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
    },
  );

  testWidgets(
    'onboarding route redirects to preserved target once onboarding is complete',
    (tester) async {
      late _FakeAuthNotifier authNotifier;
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => authNotifier = _FakeAuthNotifier(
              AuthState.authenticated(_userMissingOnboardingData()),
            ),
          ),
          groupsRepositoryProvider.overrideWithValue(_FakeGroupsRepository()),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      router.go('/onboarding?from=%2Fjoin%2FABC123');
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);

      authNotifier.setAuthState(AuthState.authenticated(_completedUser()));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.toString(), '/join/ABC123');
    },
  );
}
