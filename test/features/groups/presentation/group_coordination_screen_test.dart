import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/features/groups/domain/coordination_model.dart';
import 'package:ingame/features/groups/domain/group_model.dart';
import 'package:ingame/features/groups/domain/membership_model.dart';
import 'package:ingame/features/groups/presentation/providers/group_coordination_provider.dart';
import 'package:ingame/features/groups/presentation/providers/group_detail_provider.dart';
import 'package:ingame/features/groups/presentation/screens/group_coordination_screen.dart';
import 'package:ingame/l10n/app_localizations.dart';

class _FakeCoordinationNotifier extends GroupCoordinationNotifier {
  _FakeCoordinationNotifier(this._initialState) : super('group-1');

  final GroupCoordinationState _initialState;

  @override
  Future<GroupCoordinationState> build() async => _initialState;
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._state);

  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

class _FakeGroupDetailNotifier extends GroupDetailNotifier {
  _FakeGroupDetailNotifier(this._state) : super('group-1');

  final GroupDetailState _state;

  @override
  Future<GroupDetailState> build() async => _state;
}

void main() {
  testWidgets('coordination screen uses permission-aware affordances and richer planning UI', (
    tester,
  ) async {
    final notifier = _FakeCoordinationNotifier(
      GroupCoordinationState(
        windows: [
          ScheduledReadyWindow(
            id: 'window-1',
            groupId: 'group-1',
            userId: 'owner-1',
            displayName: 'Owner',
            startsAt: DateTime.utc(2026, 6, 6, 20),
            endsAt: DateTime.utc(2026, 6, 6, 22),
            source: 'manual',
            createdAt: DateTime.utc(2026, 6, 5, 10),
          ),
        ],
        sessions: [
          GroupSession(
            id: 'session-1',
            groupId: 'group-1',
            proposedBy: 'owner-1',
            proposedByDisplayName: 'Owner',
            title: 'Valheim Night',
            game: 'Valheim',
            notes: 'Bring potions',
            startsAt: DateTime.utc(2026, 6, 6, 20),
            status: 'proposed',
            createdAt: DateTime.utc(2026, 6, 5, 10),
            rsvps: [
              SessionRsvp(
                id: 'rsvp-1',
                sessionId: 'session-1',
                userId: 'member-1',
                displayName: 'Member',
                response: 'maybe',
                updatedAt: DateTime.utc(2026, 6, 5, 10, 5),
              ),
            ],
          ),
        ],
        activity: [
          GroupActivityEvent(
            id: 'activity-1',
            groupId: 'group-1',
            actorUserId: 'owner-1',
            actorDisplayName: 'Owner',
            type: 'session_proposed',
            message: 'Owner proposed a session',
            sessionId: 'session-1',
            createdAt: DateTime.utc(2026, 6, 5, 10),
          ),
        ],
      ),
    );
    final authNotifier = _FakeAuthNotifier(
      const AuthState.authenticated(
        User(id: 'member-1', displayName: 'Member', timezone: 'UTC'),
      ),
    );
    final detailNotifier = _FakeGroupDetailNotifier(
      const GroupDetailState(
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
        currentUserId: 'member-1',
        currentUserRole: 'member',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupCoordinationNotifierProvider(
            'group-1',
          ).overrideWith(() => notifier),
          authNotifierProvider.overrideWith(() => authNotifier),
          groupDetailNotifierProvider('group-1').overrideWith(() => detailNotifier),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupCoordinationScreen(groupId: 'group-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verfügbarkeitskalender'), findsOneWidget);
    expect(find.text('Diese Woche'), findsOneWidget);
    expect(find.text('Valheim Night'), findsOneWidget);
    expect(find.text('Bring potions'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Aktivität'), findsOneWidget);
    expect(find.text('Vielleicht'), findsOneWidget);
    expect(find.text('Owner hat eine Session vorgeschlagen'), findsOneWidget);
  });
}
