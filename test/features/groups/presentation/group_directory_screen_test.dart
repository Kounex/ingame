import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/features/groups/data/groups_repository.dart';
import 'package:ingame/features/groups/domain/group_model.dart';
import 'package:ingame/features/groups/presentation/screens/group_directory_screen.dart';
import 'package:ingame/l10n/app_localizations.dart';

class _SequencedGroupsRepository extends GroupsRepository {
  _SequencedGroupsRepository() : super(dio: Dio());

  final Map<String?, Completer<List<Group>>> _responses = {};
  final Map<String?, List<Group>> _currentResults = {};
  int createJoinRequestCalls = 0;

  void complete(String? search, List<Group> groups) {
    _currentResults[search] = groups;
    _responses.putIfAbsent(search, Completer<List<Group>>.new).complete(groups);
  }

  @override
  Future<List<Group>> discoverGroups({String? search}) {
    final pending = _responses.putIfAbsent(search, Completer<List<Group>>.new);
    if (!pending.isCompleted) {
      return pending.future;
    }
    return Future.value(List<Group>.of(_currentResults[search] ?? const []));
  }

  @override
  Future<void> createJoinRequest(String groupId) async {
    createJoinRequestCalls++;
    for (final search in _currentResults.keys.toList()) {
      _currentResults[search] = (_currentResults[search] ?? const [])
          .map(
            (group) => group.id == groupId
                ? group.copyWith(hasPendingJoinRequest: true)
                : group,
          )
          .toList();
    }
  }
}

Group _groupFixture(
  String id,
  String name, {
  String joinMode = 'open',
  bool hasPendingJoinRequest = false,
}) {
  return Group(
    id: id,
    name: name,
    inviteCode: 'CODE$id',
    isDiscoverable: true,
    joinMode: joinMode,
    createdBy: 'owner-1',
    memberCount: 4,
    hasPendingJoinRequest: hasPendingJoinRequest,
  );
}

void main() {
  testWidgets('directory search ignores stale result races', (tester) async {
    final repository = _SequencedGroupsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [groupsRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupDirectoryScreen(),
        ),
      ),
    );

    repository.complete(null, [_groupFixture('initial', 'Initial Group')]);
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'raid');
    await tester.pump(const Duration(milliseconds: 350));

    await tester.enterText(find.byType(TextFormField), 'valo');
    await tester.pump(const Duration(milliseconds: 350));

    repository.complete('valo', [_groupFixture('new', 'Valorant Squad')]);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Valorant Squad'), findsOneWidget);

    repository.complete('raid', [_groupFixture('old', 'Raid Night')]);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Valorant Squad'), findsOneWidget);
    expect(find.text('Raid Night'), findsNothing);
  });

  testWidgets('directory disables approval request CTA after success', (
    tester,
  ) async {
    final repository = _SequencedGroupsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [groupsRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupDirectoryScreen(),
        ),
      ),
    );

    repository.complete(null, [
      _groupFixture('approval', 'Approval Squad', joinMode: 'approval'),
    ]);
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Request to Join'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(repository.createJoinRequestCalls, 1);
    await tester.tap(
      find.byKey(const ValueKey('group-directory-action-approval')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(repository.createJoinRequestCalls, 1);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'directory keeps approval request CTA disabled from backend state',
    (tester) async {
      final repository = _SequencedGroupsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [groupsRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: GroupDirectoryScreen(),
          ),
        ),
      );

      repository.complete(null, [
        _groupFixture(
          'approval',
          'Approval Squad',
          joinMode: 'approval',
          hasPendingJoinRequest: true,
        ),
      ]);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Request Sent'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('group-directory-action-approval')),
      );
      await tester.pump();

      expect(repository.createJoinRequestCalls, 0);
    },
  );
}
