import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/features/groups/data/groups_repository.dart';
import 'package:ingame/features/groups/domain/group_model.dart';
import 'package:ingame/features/groups/domain/membership_model.dart';
import 'package:ingame/features/groups/presentation/providers/group_detail_provider.dart';
import 'package:ingame/features/groups/presentation/screens/group_settings_screen.dart';
import 'package:ingame/l10n/app_localizations.dart';
import 'package:ingame/shared/providers/presence_provider.dart';
import 'package:ingame/shared/services/app_haptics.dart';
import 'package:ingame/shared/widgets/status_indicator.dart';

class _FakeGroupDetailNotifier extends GroupDetailNotifier {
  _FakeGroupDetailNotifier(this._initialState) : super('group-1');

  final GroupDetailState _initialState;
  String? updatedUserId;
  String? updatedRole;

  @override
  Future<GroupDetailState> build() async => _initialState;

  @override
  Future<void> updateMemberRole(String userId, String role) async {
    updatedUserId = userId;
    updatedRole = role;
  }
}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => const AuthState.authenticated(
    User(id: 'owner-1', displayName: 'Owner', timezone: 'UTC'),
  );
}

class _MutableGroupsRepository extends GroupsRepository {
  _MutableGroupsRepository()
    : _group = const Group(
        id: 'group-1',
        name: 'Raid Night',
        inviteCode: 'ABC123',
        isDiscoverable: false,
        joinMode: 'open',
        createdBy: 'owner-1',
        memberCount: 2,
      ),
      _members = [
        const GroupMember(
          id: 'membership-owner',
          userId: 'owner-1',
          displayName: 'Owner',
          role: 'owner',
        ),
        const GroupMember(
          id: 'membership-member',
          userId: 'member-1',
          displayName: 'Member',
          role: 'member',
        ),
      ],
      super(dio: Dio());

  final Group _group;
  final List<GroupMember> _members;

  @override
  Future<Group> getGroup(String id) async => _group;

  @override
  Future<List<GroupMember>> listMembers(String groupId) async =>
      List.of(_members);

  @override
  Future<void> updateMemberRole(
    String groupId,
    String userId,
    String role,
  ) async {
    final index = _members.indexWhere((member) => member.userId == userId);
    _members[index] = _members[index].copyWith(role: role);
  }

  @override
  Future<List<JoinRequest>> listJoinRequests(String groupId) async => const [];
}

GroupDetailState _detailState() {
  return const GroupDetailState(
    group: Group(
      id: 'group-1',
      name: 'Raid Night',
      inviteCode: 'ABC123',
      isDiscoverable: false,
      joinMode: 'open',
      createdBy: 'owner-1',
      memberCount: 2,
    ),
    members: [
      GroupMember(
        id: 'membership-owner',
        userId: 'owner-1',
        displayName: 'Owner',
        role: 'owner',
      ),
      GroupMember(
        id: 'membership-member',
        userId: 'member-1',
        displayName: 'Member',
        role: 'member',
      ),
    ],
    currentUserId: 'owner-1',
    currentUserRole: 'owner',
  );
}

void main() {
  testWidgets('owner can promote a member from group settings', (tester) async {
    final notifier = _FakeGroupDetailNotifier(_detailState());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupDetailNotifierProvider('group-1').overrideWith(() => notifier),
          groupMemberStatusProvider.overrideWith(
            (ref, key) => UserStatus.online,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupSettingsScreen(groupId: 'group-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byIcon(Icons.more_horiz).last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Promote'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Promote'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));

    expect(notifier.updatedUserId, 'member-1');
    expect(notifier.updatedRole, 'admin');
  });

  testWidgets('promotion refreshes member role to admin in the UI', (
    tester,
  ) async {
    final repository = _MutableGroupsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          groupsRepositoryProvider.overrideWithValue(repository),
          groupMemberStatusProvider.overrideWith(
            (ref, key) => UserStatus.online,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupSettingsScreen(groupId: 'group-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Admin'), findsNothing);

    await tester.ensureVisible(find.byIcon(Icons.more_horiz).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_horiz).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Promote'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Promote'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));

    expect(find.text('Admin'), findsOneWidget);
  });

  testWidgets('member action menu triggers haptics on open and selection', (
    tester,
  ) async {
    final notifier = _FakeGroupDetailNotifier(_detailState());
    var selectionHaptics = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupDetailNotifierProvider('group-1').overrideWith(() => notifier),
          groupMemberStatusProvider.overrideWith(
            (ref, key) => UserStatus.online,
          ),
          appHapticsProvider.overrideWithValue(
            AppHaptics(
              isWeb: false,
              platform: TargetPlatform.android,
              selectionCallback: () async => selectionHaptics++,
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupSettingsScreen(groupId: 'group-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byIcon(Icons.more_horiz).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_horiz).last);
    await tester.pumpAndSettle();

    expect(selectionHaptics, 1);

    await tester.tap(find.text('Promote'));
    await tester.pumpAndSettle();

    expect(selectionHaptics, 2);
  });
}
