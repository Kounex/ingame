import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/features/groups/data/groups_repository.dart';
import 'package:ingame/features/groups/domain/group_model.dart';
import 'package:ingame/features/groups/presentation/screens/join_group_screen.dart';
import 'package:ingame/l10n/app_localizations.dart';
import 'package:ingame/shared/services/app_haptics.dart';

class _FakeGroupsRepository extends GroupsRepository {
  _FakeGroupsRepository(this.previewGroup) : super(dio: Dio());

  final Group previewGroup;
  int previewCalls = 0;
  int createJoinRequestCalls = 0;
  int createJoinRequestByInviteCodeCalls = 0;
  int joinByInviteCodeCalls = 0;

  @override
  Future<Group> previewByInviteCode(String code) async {
    previewCalls++;
    return previewGroup;
  }

  @override
  Future<void> createJoinRequest(String groupId) async {
    createJoinRequestCalls++;
  }

  @override
  Future<void> createJoinRequestByInviteCode(String code) async {
    createJoinRequestByInviteCodeCalls++;
  }

  @override
  Future<Group> joinByInviteCode(String code) async {
    joinByInviteCodeCalls++;
    return previewGroup;
  }
}

void main() {
  testWidgets('approval invite flow sends a join request instead of joining', (
    tester,
  ) async {
    final repository = _FakeGroupsRepository(
      const Group(
        id: 'group-1',
        name: 'Approval Group',
        inviteCode: 'ABC123',
        isDiscoverable: false,
        joinMode: 'approval',
        createdBy: 'owner-1',
        memberCount: 4,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupsRepositoryProvider.overrideWithValue(repository),
          appHapticsProvider.overrideWithValue(
            const AppHaptics(
              isWeb: false,
              platform: TargetPlatform.android,
              lightImpactCallback: _noopHaptic,
            ),
          ),
        ],
        child: const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: JoinGroupScreen(inviteCode: 'ABC123'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Approval required'), findsOneWidget);

    await tester.tap(find.text('Request to Join'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(repository.createJoinRequestByInviteCodeCalls, 1);
    expect(repository.createJoinRequestCalls, 0);
    expect(repository.joinByInviteCodeCalls, 0);
    expect(find.text('Join request sent!'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 300));
  });
}

Future<void> _noopHaptic() async {}
