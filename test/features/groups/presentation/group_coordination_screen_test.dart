import 'dart:io';

import 'package:dio/dio.dart';
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
import 'package:ingame/shared/services/app_haptics.dart';

class _FakeCoordinationNotifier extends GroupCoordinationNotifier {
  _FakeCoordinationNotifier(this._initialState) : super('group-1');

  final GroupCoordinationState _initialState;
  String? deletedWindowId;
  String? deletedSessionId;
  String? updatedSessionId;
  String? updatedStatus;
  String? rsvpSessionId;
  String? rsvpResponse;

  @override
  Future<GroupCoordinationState> build() async => _initialState;

  @override
  Future<void> deleteScheduledReady(String windowId) async {
    deletedWindowId = windowId;
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    deletedSessionId = sessionId;
  }

  @override
  Future<void> updateSession(
    String sessionId, {
    String? title,
    String? game,
    DateTime? startsAt,
    String? notes,
    String? status,
  }) async {
    updatedSessionId = sessionId;
    updatedStatus = status;
  }

  @override
  Future<void> rsvpToSession(String sessionId, String response) async {
    rsvpSessionId = sessionId;
    rsvpResponse = response;
  }
}

class _FailingDeleteCoordinationNotifier extends _FakeCoordinationNotifier {
  _FailingDeleteCoordinationNotifier(super.initialState);

  @override
  Future<void> deleteSession(String sessionId) async {
    final request = RequestOptions(path: '/groups/group-1/sessions/$sessionId');
    throw DioException(
      requestOptions: request,
      response: Response(
        requestOptions: request,
        statusCode: 405,
        data: const {'detail': 'Method not allowed'},
      ),
      type: DioExceptionType.badResponse,
    );
  }
}

class _FailingRsvpCoordinationNotifier extends _FakeCoordinationNotifier {
  _FailingRsvpCoordinationNotifier(super.initialState);

  @override
  Future<void> rsvpToSession(String sessionId, String response) async {
    final request = RequestOptions(
      path: '/groups/group-1/sessions/$sessionId/rsvp',
    );
    throw DioException(
      requestOptions: request,
      response: Response(
        requestOptions: request,
        statusCode: 500,
        data: const {'detail': 'Server error'},
      ),
      type: DioExceptionType.badResponse,
    );
  }
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

class _FailingGroupDetailNotifier extends GroupDetailNotifier {
  _FailingGroupDetailNotifier() : super('group-1');

  @override
  Future<GroupDetailState> build() async {
    final request = RequestOptions(path: '/groups/group-1');
    throw DioException(
      requestOptions: request,
      response: Response(
        requestOptions: request,
        statusCode: 500,
        data: const {'detail': 'Server error'},
      ),
      type: DioExceptionType.badResponse,
    );
  }
}

Finder _dialogTextButton(String label) {
  return find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(TextButton, label),
  );
}

Future<void> _openSessionEditMenu(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Edit Session'));
  await tester.pumpAndSettle();
}

ScheduledReadyWindow _windowFixture({
  required String id,
  required String displayName,
  required DateTime startsAt,
  int durationHours = 2,
  String userId = 'owner-1',
}) {
  return ScheduledReadyWindow(
    id: id,
    groupId: 'group-1',
    userId: userId,
    displayName: displayName,
    startsAt: startsAt,
    endsAt: startsAt.add(Duration(hours: durationHours)),
    source: 'manual',
    createdAt: startsAt.subtract(const Duration(days: 1)),
  );
}

GroupActivityEvent _activityFixture({
  required String id,
  required String actorUserId,
  required String actorDisplayName,
  required String type,
  required DateTime createdAt,
  String? message,
  String? sessionId,
  String? scheduledReadyWindowId,
}) {
  return GroupActivityEvent(
    id: id,
    groupId: 'group-1',
    actorUserId: actorUserId,
    actorDisplayName: actorDisplayName,
    type: type,
    message: message ?? '$actorDisplayName $type',
    sessionId: sessionId,
    scheduledReadyWindowId: scheduledReadyWindowId,
    createdAt: createdAt,
  );
}

void main() {
  testWidgets(
    'coordination screen uses permission-aware affordances and richer planning UI',
    (tester) async {
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
            groupDetailNotifierProvider(
              'group-1',
            ).overrideWith(() => detailNotifier),
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

      expect(find.text('Bevorstehende Fenster'), findsOneWidget);
      expect(find.text('Diese Woche'), findsNothing);
      expect(find.text('Valheim Night'), findsOneWidget);
      expect(find.text('Bring potions'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(
        find.byKey(const Key('session-rsvp-count-maybe-session-1')),
        findsOneWidget,
      );
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('Aktivität'), findsOneWidget);
      expect(find.text('Owner hat eine Session vorgeschlagen'), findsOneWidget);
    },
  );

  testWidgets(
    'activity journal shows recent highlights and collapsed history groups by default',
    (tester) async {
      final now = DateTime.now().toUtc();
      final notifier = _FakeCoordinationNotifier(
        GroupCoordinationState(
          activity: [
            _activityFixture(
              id: 'activity-1',
              actorUserId: 'owner-1',
              actorDisplayName: 'Owner',
              type: 'session_proposed',
              createdAt: now.subtract(const Duration(minutes: 8)),
              sessionId: 'session-1',
            ),
            _activityFixture(
              id: 'activity-2',
              actorUserId: 'member-1',
              actorDisplayName: 'Kai',
              type: 'scheduled_ready_updated',
              createdAt: now.subtract(const Duration(minutes: 24)),
              scheduledReadyWindowId: 'window-1',
            ),
            _activityFixture(
              id: 'activity-3',
              actorUserId: 'member-2',
              actorDisplayName: 'Lena',
              type: 'session_updated',
              createdAt: now.subtract(const Duration(hours: 3)),
              sessionId: 'session-1',
            ),
            _activityFixture(
              id: 'activity-4',
              actorUserId: 'member-3',
              actorDisplayName: 'Scout',
              type: 'session_deleted',
              createdAt: now.subtract(const Duration(days: 1, hours: 1)),
              sessionId: 'session-2',
            ),
          ],
        ),
      );
      final authNotifier = _FakeAuthNotifier(
        const AuthState.authenticated(
          User(id: 'member-1', displayName: 'Kai', timezone: 'UTC'),
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
            memberCount: 4,
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
              displayName: 'Kai',
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
            groupDetailNotifierProvider(
              'group-1',
            ).overrideWith(() => detailNotifier),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: GroupCoordinationScreen(groupId: 'group-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Activity'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.byKey(const Key('activity-recent-list')), findsOneWidget);
      expect(find.text('Today (3)'), findsNothing);
      expect(find.text('Yesterday (1)'), findsOneWidget);
      expect(find.text('Scout removed a session'), findsNothing);
    },
  );

  testWidgets(
    'activity history excludes entries already surfaced in recent highlights',
    (tester) async {
      final now = DateTime.now().toUtc();
      final notifier = _FakeCoordinationNotifier(
        GroupCoordinationState(
          activity: [
            _activityFixture(
              id: 'activity-1',
              actorUserId: 'owner-1',
              actorDisplayName: 'Owner',
              type: 'session_proposed',
              createdAt: now.subtract(const Duration(minutes: 8)),
              sessionId: 'session-1',
            ),
            _activityFixture(
              id: 'activity-2',
              actorUserId: 'member-1',
              actorDisplayName: 'Kai',
              type: 'scheduled_ready_updated',
              createdAt: now.subtract(const Duration(minutes: 24)),
              scheduledReadyWindowId: 'window-1',
            ),
            _activityFixture(
              id: 'activity-3',
              actorUserId: 'member-2',
              actorDisplayName: 'Lena',
              type: 'session_updated',
              createdAt: now.subtract(const Duration(hours: 3)),
              sessionId: 'session-1',
            ),
            _activityFixture(
              id: 'activity-4',
              actorUserId: 'member-3',
              actorDisplayName: 'Scout',
              type: 'session_deleted',
              createdAt: now.subtract(const Duration(days: 1, hours: 1)),
              sessionId: 'session-2',
            ),
          ],
        ),
      );
      final authNotifier = _FakeAuthNotifier(
        const AuthState.authenticated(
          User(id: 'member-1', displayName: 'Kai', timezone: 'UTC'),
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
            memberCount: 4,
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
              displayName: 'Kai',
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
            groupDetailNotifierProvider(
              'group-1',
            ).overrideWith(() => detailNotifier),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: GroupCoordinationScreen(groupId: 'group-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Activity'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('activity-history-group-yesterday')),
      );
      await tester.pumpAndSettle();

      final yesterdayGroup = find.byKey(
        const Key('activity-history-group-yesterday'),
      );
      expect(
        find.descendant(
          of: yesterdayGroup,
          matching: find.text('Owner proposed a session'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: yesterdayGroup,
          matching: find.text('Kai updated a ready window'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: yesterdayGroup,
          matching: find.text('Lena updated a session'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: yesterdayGroup,
          matching: find.text('Scout removed a session'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'activity journal aggregates adjacent rsvp updates in recent highlights',
    (tester) async {
      final now = DateTime.now().toUtc();
      final notifier = _FakeCoordinationNotifier(
        GroupCoordinationState(
          activity: [
            _activityFixture(
              id: 'activity-1',
              actorUserId: 'member-1',
              actorDisplayName: 'Kai',
              type: 'session_rsvp_updated',
              createdAt: now.subtract(const Duration(minutes: 4)),
              sessionId: 'session-1',
            ),
            _activityFixture(
              id: 'activity-2',
              actorUserId: 'member-2',
              actorDisplayName: 'Lena',
              type: 'session_rsvp_updated',
              createdAt: now.subtract(const Duration(minutes: 9)),
              sessionId: 'session-1',
            ),
            _activityFixture(
              id: 'activity-3',
              actorUserId: 'owner-1',
              actorDisplayName: 'Owner',
              type: 'session_proposed',
              createdAt: now.subtract(const Duration(minutes: 25)),
              sessionId: 'session-1',
            ),
          ],
        ),
      );
      final authNotifier = _FakeAuthNotifier(
        const AuthState.authenticated(
          User(id: 'member-1', displayName: 'Kai', timezone: 'UTC'),
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
            memberCount: 3,
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
              displayName: 'Kai',
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
            groupDetailNotifierProvider(
              'group-1',
            ).overrideWith(() => detailNotifier),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: GroupCoordinationScreen(groupId: 'group-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Activity'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('2 RSVP updates'), findsOneWidget);
      expect(find.text('Kai updated an RSVP'), findsNothing);
      expect(find.text('Lena updated an RSVP'), findsNothing);
    },
  );

  testWidgets('activity journal type filters narrow recent and history items', (
    tester,
  ) async {
    final now = DateTime.now().toUtc();
    final notifier = _FakeCoordinationNotifier(
      GroupCoordinationState(
        activity: [
          _activityFixture(
            id: 'activity-1',
            actorUserId: 'owner-1',
            actorDisplayName: 'Owner',
            type: 'session_proposed',
            createdAt: now.subtract(const Duration(minutes: 5)),
            sessionId: 'session-1',
          ),
          _activityFixture(
            id: 'activity-2',
            actorUserId: 'member-1',
            actorDisplayName: 'Kai',
            type: 'scheduled_ready_updated',
            createdAt: now.subtract(const Duration(minutes: 25)),
            scheduledReadyWindowId: 'window-1',
          ),
          _activityFixture(
            id: 'activity-3',
            actorUserId: 'member-2',
            actorDisplayName: 'Lena',
            type: 'session_rsvp_updated',
            createdAt: now.subtract(const Duration(days: 1, minutes: 25)),
            sessionId: 'session-1',
          ),
        ],
      ),
    );
    final authNotifier = _FakeAuthNotifier(
      const AuthState.authenticated(
        User(id: 'member-1', displayName: 'Kai', timezone: 'UTC'),
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
          memberCount: 3,
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
            displayName: 'Kai',
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
          groupDetailNotifierProvider(
            'group-1',
          ).overrideWith(() => detailNotifier),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupCoordinationScreen(groupId: 'group-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Activity'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('activity-filter-sessions')));
    await tester.pumpAndSettle();

    expect(find.text('Owner proposed a session'), findsOneWidget);
    expect(find.text('Kai updated availability'), findsNothing);
    expect(find.text('Lena updated an RSVP'), findsNothing);
  });

  testWidgets(
    'upcoming windows preview shows only the next five and opens the agenda sheet for the rest',
    (tester) async {
      final notifier = _FakeCoordinationNotifier(
        GroupCoordinationState(
          windows: [
            _windowFixture(
              id: 'window-1',
              displayName: 'Alpha',
              startsAt: DateTime.utc(2030, 6, 1, 18),
            ),
            _windowFixture(
              id: 'window-2',
              displayName: 'Bravo',
              startsAt: DateTime.utc(2030, 6, 2, 18),
            ),
            _windowFixture(
              id: 'window-3',
              displayName: 'Charlie',
              startsAt: DateTime.utc(2030, 6, 3, 18),
            ),
            _windowFixture(
              id: 'window-4',
              displayName: 'Delta',
              startsAt: DateTime.utc(2030, 6, 4, 18),
            ),
            _windowFixture(
              id: 'window-5',
              displayName: 'Echo',
              startsAt: DateTime.utc(2030, 6, 5, 18),
            ),
            _windowFixture(
              id: 'window-6',
              displayName: 'Foxtrot',
              startsAt: DateTime.utc(2030, 6, 6, 18),
            ),
            _windowFixture(
              id: 'window-7',
              displayName: 'Golf',
              startsAt: DateTime.utc(2030, 6, 7, 18),
            ),
          ],
        ),
      );
      final authNotifier = _FakeAuthNotifier(
        const AuthState.authenticated(
          User(id: 'owner-1', displayName: 'Owner', timezone: 'UTC'),
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
            memberCount: 1,
          ),
          members: [
            GroupMember(
              id: 'membership-owner',
              userId: 'owner-1',
              displayName: 'Owner',
              role: 'owner',
            ),
          ],
          currentUserId: 'owner-1',
          currentUserRole: 'owner',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupCoordinationNotifierProvider(
              'group-1',
            ).overrideWith(() => notifier),
            authNotifierProvider.overrideWith(() => authNotifier),
            groupDetailNotifierProvider(
              'group-1',
            ).overrideWith(() => detailNotifier),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: GroupCoordinationScreen(groupId: 'group-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upcoming windows'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Echo'), findsOneWidget);
      expect(find.text('Foxtrot'), findsNothing);
      expect(find.text('Golf'), findsNothing);
      expect(find.text('View all (2 more)'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('View all (2 more)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('View all (2 more)'));
      await tester.pumpAndSettle();

      expect(find.text('All upcoming windows'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Foxtrot'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Foxtrot'), findsOneWidget);
      expect(find.text('Golf'), findsOneWidget);
    },
  );

  testWidgets(
    'upcoming windows render standout grouped day headers and dividers',
    (tester) async {
      final notifier = _FakeCoordinationNotifier(
        GroupCoordinationState(
          windows: [
            _windowFixture(
              id: 'window-1',
              displayName: 'Alpha',
              startsAt: DateTime.utc(2030, 6, 1, 18),
            ),
            _windowFixture(
              id: 'window-2',
              displayName: 'Bravo',
              startsAt: DateTime.utc(2030, 6, 1, 21),
            ),
            _windowFixture(
              id: 'window-3',
              displayName: 'Charlie',
              startsAt: DateTime.utc(2030, 6, 2, 18),
            ),
          ],
        ),
      );
      final authNotifier = _FakeAuthNotifier(
        const AuthState.authenticated(
          User(id: 'owner-1', displayName: 'Owner', timezone: 'UTC'),
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
            memberCount: 1,
          ),
          members: [
            GroupMember(
              id: 'membership-owner',
              userId: 'owner-1',
              displayName: 'Owner',
              role: 'owner',
            ),
          ],
          currentUserId: 'owner-1',
          currentUserRole: 'owner',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupCoordinationNotifierProvider(
              'group-1',
            ).overrideWith(() => notifier),
            authNotifierProvider.overrideWith(() => authNotifier),
            groupDetailNotifierProvider(
              'group-1',
            ).overrideWith(() => detailNotifier),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: GroupCoordinationScreen(groupId: 'group-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('agenda-day-header-2030-06-01')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('agenda-day-header-2030-06-02')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('agenda-day-divider-2030-06-02')),
        findsOneWidget,
      );
    },
  );

  testWidgets('upcoming windows empty state is upcoming-focused', (
    tester,
  ) async {
    final notifier = _FakeCoordinationNotifier(
      GroupCoordinationState(
        windows: [
          _windowFixture(
            id: 'window-past',
            displayName: 'Past Window',
            startsAt: DateTime.utc(2020, 6, 1, 18),
          ),
        ],
      ),
    );
    final authNotifier = _FakeAuthNotifier(
      const AuthState.authenticated(
        User(id: 'owner-1', displayName: 'Owner', timezone: 'UTC'),
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
          memberCount: 1,
        ),
        members: [
          GroupMember(
            id: 'membership-owner',
            userId: 'owner-1',
            displayName: 'Owner',
            role: 'owner',
          ),
        ],
        currentUserId: 'owner-1',
        currentUserRole: 'owner',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupCoordinationNotifierProvider(
            'group-1',
          ).overrideWith(() => notifier),
          authNotifierProvider.overrideWith(() => authNotifier),
          groupDetailNotifierProvider(
            'group-1',
          ).overrideWith(() => detailNotifier),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupCoordinationScreen(groupId: 'group-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No upcoming ready windows.'), findsOneWidget);
    expect(find.text('No scheduled ready windows yet.'), findsNothing);
  });

  testWidgets('summary card counts only upcoming ready windows', (
    tester,
  ) async {
    final notifier = _FakeCoordinationNotifier(
      GroupCoordinationState(
        windows: [
          _windowFixture(
            id: 'window-past-1',
            displayName: 'Past Alpha',
            startsAt: DateTime.utc(2020, 6, 1, 18),
          ),
          _windowFixture(
            id: 'window-past-2',
            displayName: 'Past Bravo',
            startsAt: DateTime.utc(2020, 6, 2, 18),
          ),
          _windowFixture(
            id: 'window-future-1',
            displayName: 'Future Alpha',
            startsAt: DateTime.utc(2099, 6, 1, 18),
          ),
          _windowFixture(
            id: 'window-future-2',
            displayName: 'Future Bravo',
            startsAt: DateTime.utc(2099, 6, 2, 18),
          ),
        ],
      ),
    );
    final authNotifier = _FakeAuthNotifier(
      const AuthState.authenticated(
        User(id: 'owner-1', displayName: 'Owner', timezone: 'UTC'),
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
          memberCount: 1,
        ),
        members: [
          GroupMember(
            id: 'membership-owner',
            userId: 'owner-1',
            displayName: 'Owner',
            role: 'owner',
          ),
        ],
        currentUserId: 'owner-1',
        currentUserRole: 'owner',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupCoordinationNotifierProvider(
            'group-1',
          ).overrideWith(() => notifier),
          authNotifierProvider.overrideWith(() => authNotifier),
          groupDetailNotifierProvider(
            'group-1',
          ).overrideWith(() => detailNotifier),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupCoordinationScreen(groupId: 'group-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 windows'), findsOneWidget);
    expect(find.text('4 windows'), findsNothing);
    expect(find.text('Future Alpha'), findsOneWidget);
    expect(find.text('Future Bravo'), findsOneWidget);
    expect(find.text('Past Alpha'), findsNothing);
    expect(find.text('Past Bravo'), findsNothing);
  });

  testWidgets(
    'upcoming windows avoid duplicate weekday headings and use a compact You chip',
    (tester) async {
      final notifier = _FakeCoordinationNotifier(
        GroupCoordinationState(
          windows: [
            _windowFixture(
              id: 'window-1',
              displayName: 'Owner',
              startsAt: DateTime.utc(2026, 6, 7, 18),
            ),
          ],
        ),
      );
      final authNotifier = _FakeAuthNotifier(
        const AuthState.authenticated(
          User(id: 'owner-1', displayName: 'Owner', timezone: 'UTC'),
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
            memberCount: 1,
          ),
          members: [
            GroupMember(
              id: 'membership-owner',
              userId: 'owner-1',
              displayName: 'Owner',
              role: 'owner',
            ),
          ],
          currentUserId: 'owner-1',
          currentUserRole: 'owner',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupCoordinationNotifierProvider(
              'group-1',
            ).overrideWith(() => notifier),
            authNotifierProvider.overrideWith(() => authNotifier),
            groupDetailNotifierProvider(
              'group-1',
            ).overrideWith(() => detailNotifier),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: GroupCoordinationScreen(groupId: 'group-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Sun, Sun'), findsNothing);

      final youText = tester.widget<Text>(find.text('You'));
      expect(youText.style?.fontSize, 12);
    },
  );

  testWidgets('deleting a ready window requires confirmation', (tester) async {
    final notifier = _FakeCoordinationNotifier(
      GroupCoordinationState(
        windows: [
          ScheduledReadyWindow(
            id: 'window-1',
            groupId: 'group-1',
            userId: 'owner-1',
            displayName: 'Owner',
            startsAt: DateTime.utc(2099, 6, 6, 20),
            endsAt: DateTime.utc(2099, 6, 6, 22),
            source: 'manual',
            createdAt: DateTime.utc(2099, 6, 5, 10),
          ),
        ],
      ),
    );
    final authNotifier = _FakeAuthNotifier(
      const AuthState.authenticated(
        User(id: 'owner-1', displayName: 'Owner', timezone: 'UTC'),
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
          memberCount: 1,
        ),
        members: [
          GroupMember(
            id: 'membership-owner',
            userId: 'owner-1',
            displayName: 'Owner',
            role: 'owner',
          ),
        ],
        currentUserId: 'owner-1',
        currentUserRole: 'owner',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupCoordinationNotifierProvider(
            'group-1',
          ).overrideWith(() => notifier),
          authNotifierProvider.overrideWith(() => authNotifier),
          groupDetailNotifierProvider(
            'group-1',
          ).overrideWith(() => detailNotifier),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupCoordinationScreen(groupId: 'group-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete ready window?'), findsOneWidget);
    expect(notifier.deletedWindowId, isNull);

    await tester.tap(_dialogTextButton('Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(notifier.deletedWindowId, 'window-1');
  });

  testWidgets('cancelling a session requires confirmation before saving', (
    tester,
  ) async {
    final notifier = _FakeCoordinationNotifier(
      GroupCoordinationState(
        sessions: [
          GroupSession(
            id: 'session-1',
            groupId: 'group-1',
            proposedBy: 'owner-1',
            proposedByDisplayName: 'Owner',
            title: 'Valheim Night',
            game: 'Valheim',
            startsAt: DateTime.utc(2026, 6, 6, 20),
            status: 'proposed',
            createdAt: DateTime.utc(2026, 6, 5, 10),
          ),
        ],
      ),
    );
    final authNotifier = _FakeAuthNotifier(
      const AuthState.authenticated(
        User(id: 'owner-1', displayName: 'Owner', timezone: 'UTC'),
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
          memberCount: 1,
        ),
        members: [
          GroupMember(
            id: 'membership-owner',
            userId: 'owner-1',
            displayName: 'Owner',
            role: 'owner',
          ),
        ],
        currentUserId: 'owner-1',
        currentUserRole: 'owner',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupCoordinationNotifierProvider(
            'group-1',
          ).overrideWith(() => notifier),
          authNotifierProvider.overrideWith(() => authNotifier),
          groupDetailNotifierProvider(
            'group-1',
          ).overrideWith(() => detailNotifier),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupCoordinationScreen(groupId: 'group-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _openSessionEditMenu(tester);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelled').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel session?'), findsOneWidget);
    expect(notifier.updatedSessionId, isNull);

    await tester.tap(_dialogTextButton('Cancel Session'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(notifier.updatedSessionId, 'session-1');
    expect(notifier.updatedStatus, 'cancelled');
  });

  testWidgets('deleting a session from card actions requires confirmation', (
    tester,
  ) async {
    final notifier = _FakeCoordinationNotifier(
      GroupCoordinationState(
        sessions: [
          GroupSession(
            id: 'session-1',
            groupId: 'group-1',
            proposedBy: 'owner-1',
            proposedByDisplayName: 'Owner',
            title: 'Valheim Night',
            game: 'Valheim',
            startsAt: DateTime.utc(2026, 6, 6, 20),
            status: 'proposed',
            createdAt: DateTime.utc(2026, 6, 5, 10),
          ),
        ],
      ),
    );
    final authNotifier = _FakeAuthNotifier(
      const AuthState.authenticated(
        User(id: 'owner-1', displayName: 'Owner', timezone: 'UTC'),
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
          memberCount: 1,
        ),
        members: [
          GroupMember(
            id: 'membership-owner',
            userId: 'owner-1',
            displayName: 'Owner',
            role: 'owner',
          ),
        ],
        currentUserId: 'owner-1',
        currentUserRole: 'owner',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupCoordinationNotifierProvider(
            'group-1',
          ).overrideWith(() => notifier),
          authNotifierProvider.overrideWith(() => authNotifier),
          groupDetailNotifierProvider(
            'group-1',
          ).overrideWith(() => detailNotifier),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupCoordinationScreen(groupId: 'group-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Session'));
    await tester.pumpAndSettle();

    expect(find.text('Delete session?'), findsOneWidget);
    expect(notifier.deletedSessionId, isNull);

    await tester.tap(_dialogTextButton('Delete Session'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(notifier.deletedSessionId, 'session-1');
  });

  testWidgets('session delete 405 shows a friendly server error', (
    tester,
  ) async {
    final notifier = _FailingDeleteCoordinationNotifier(
      GroupCoordinationState(
        sessions: [
          GroupSession(
            id: 'session-1',
            groupId: 'group-1',
            proposedBy: 'owner-1',
            proposedByDisplayName: 'Owner',
            title: 'Valheim Night',
            game: 'Valheim',
            startsAt: DateTime.utc(2026, 6, 6, 20),
            status: 'proposed',
            createdAt: DateTime.utc(2026, 6, 5, 10),
          ),
        ],
      ),
    );
    final authNotifier = _FakeAuthNotifier(
      const AuthState.authenticated(
        User(id: 'owner-1', displayName: 'Owner', timezone: 'UTC'),
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
          memberCount: 1,
        ),
        members: [
          GroupMember(
            id: 'membership-owner',
            userId: 'owner-1',
            displayName: 'Owner',
            role: 'owner',
          ),
        ],
        currentUserId: 'owner-1',
        currentUserRole: 'owner',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupCoordinationNotifierProvider(
            'group-1',
          ).overrideWith(() => notifier),
          authNotifierProvider.overrideWith(() => authNotifier),
          groupDetailNotifierProvider(
            'group-1',
          ).overrideWith(() => detailNotifier),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupCoordinationScreen(groupId: 'group-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Session'));
    await tester.pumpAndSettle();
    await tester.tap(_dialogTextButton('Delete Session'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Server error. Please try again later.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'session cards show compact aggregates and open detail sheet on tap',
    (tester) async {
      final notifier = _FakeCoordinationNotifier(
        GroupCoordinationState(
          sessions: [
            GroupSession(
              id: 'session-1',
              groupId: 'group-1',
              proposedBy: 'owner-1',
              proposedByDisplayName: 'Owner',
              title: 'Valheim Night',
              game: 'Valheim',
              startsAt: DateTime.utc(2026, 6, 6, 20),
              notes:
                  'Bring potions, food, spare arrows, and be ready at the portal before pull time.',
              status: 'confirmed',
              createdAt: DateTime.utc(2026, 6, 5, 10),
              rsvps: [
                SessionRsvp(
                  id: 'rsvp-1',
                  sessionId: 'session-1',
                  userId: 'owner-1',
                  displayName: 'Owner',
                  response: 'in',
                  updatedAt: DateTime.utc(2026, 6, 5, 10),
                ),
                SessionRsvp(
                  id: 'rsvp-2',
                  sessionId: 'session-1',
                  userId: 'member-1',
                  displayName: 'Member',
                  response: 'maybe',
                  updatedAt: DateTime.utc(2026, 6, 5, 11),
                ),
                SessionRsvp(
                  id: 'rsvp-3',
                  sessionId: 'session-1',
                  userId: 'member-2',
                  displayName: 'Scout',
                  response: 'out',
                  updatedAt: DateTime.utc(2026, 6, 5, 12),
                ),
              ],
            ),
          ],
        ),
      );
      final authNotifier = _FakeAuthNotifier(
        const AuthState.authenticated(
          User(id: 'owner-1', displayName: 'Owner', timezone: 'UTC'),
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
            memberCount: 1,
          ),
          members: [
            GroupMember(
              id: 'membership-owner',
              userId: 'owner-1',
              displayName: 'Owner',
              role: 'owner',
            ),
          ],
          currentUserId: 'owner-1',
          currentUserRole: 'owner',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupCoordinationNotifierProvider(
              'group-1',
            ).overrideWith(() => notifier),
            authNotifierProvider.overrideWith(() => authNotifier),
            groupDetailNotifierProvider(
              'group-1',
            ).overrideWith(() => detailNotifier),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: GroupCoordinationScreen(groupId: 'group-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('session-card-session-1')), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('Owner: In'), findsNothing);
      expect(find.text('Member: Maybe'), findsNothing);
      expect(
        find.byKey(const Key('session-rsvp-count-in-session-1')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('session-rsvp-count-in-session-1')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('session-notes-preview-session-1')),
            )
            .maxLines,
        3,
      );

      await tester.tap(find.byKey(const Key('session-card-session-1')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('session-detail-sheet-session-1')),
        findsOneWidget,
      );
      expect(find.byType(ChoiceChip), findsNWidgets(3));
      expect(find.text('Owner'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Member'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Member'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Scout'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Scout'), findsWidgets);
      expect(
        find.byKey(const Key('session-notes-full-session-1')),
        findsOneWidget,
      );

      await tester.tap(find.text('Maybe'));
      await tester.pumpAndSettle();

      expect(notifier.rsvpSessionId, 'session-1');
      expect(notifier.rsvpResponse, 'maybe');
    },
  );

  testWidgets(
    'session status dropdown triggers haptics on open and selection',
    (tester) async {
      var selectionHaptics = 0;
      final notifier = _FakeCoordinationNotifier(
        GroupCoordinationState(
          sessions: [
            GroupSession(
              id: 'session-1',
              groupId: 'group-1',
              proposedBy: 'owner-1',
              proposedByDisplayName: 'Owner',
              title: 'Valheim Night',
              game: 'Valheim',
              startsAt: DateTime.utc(2026, 6, 6, 20),
              status: 'proposed',
              createdAt: DateTime.utc(2026, 6, 5, 10),
            ),
          ],
        ),
      );
      final authNotifier = _FakeAuthNotifier(
        const AuthState.authenticated(
          User(id: 'owner-1', displayName: 'Owner', timezone: 'UTC'),
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
            memberCount: 1,
          ),
          members: [
            GroupMember(
              id: 'membership-owner',
              userId: 'owner-1',
              displayName: 'Owner',
              role: 'owner',
            ),
          ],
          currentUserId: 'owner-1',
          currentUserRole: 'owner',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupCoordinationNotifierProvider(
              'group-1',
            ).overrideWith(() => notifier),
            authNotifierProvider.overrideWith(() => authNotifier),
            groupDetailNotifierProvider(
              'group-1',
            ).overrideWith(() => detailNotifier),
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
            home: GroupCoordinationScreen(groupId: 'group-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _openSessionEditMenu(tester);
      selectionHaptics = 0;
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();

      expect(selectionHaptics, 1);

      await tester.tap(find.text('Cancelled').last);
      await tester.pumpAndSettle();

      expect(selectionHaptics, 2);
    },
  );

  test('session status dropdown uses the shared dropdown selector wrapper', () {
    final source = File(
      'lib/features/groups/presentation/screens/group_coordination_screen.dart',
    ).readAsStringSync();

    expect(source, contains('AppDropdownSelector<String>.field('));
  });

  testWidgets('session RSVP failures show a recoverable error toast', (
    tester,
  ) async {
    final notifier = _FailingRsvpCoordinationNotifier(
      GroupCoordinationState(
        sessions: [
          GroupSession(
            id: 'session-1',
            groupId: 'group-1',
            proposedBy: 'owner-1',
            proposedByDisplayName: 'Owner',
            title: 'Valheim Night',
            startsAt: DateTime.utc(2099, 6, 6, 20),
            status: 'proposed',
            createdAt: DateTime.utc(2099, 6, 5, 10),
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
          groupDetailNotifierProvider(
            'group-1',
          ).overrideWith(() => detailNotifier),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupCoordinationScreen(groupId: 'group-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('session-card-session-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('In'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Server error'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('coordination screen surfaces detail-provider failures', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupCoordinationNotifierProvider('group-1').overrideWith(
            () => _FakeCoordinationNotifier(const GroupCoordinationState()),
          ),
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(
              const AuthState.authenticated(
                User(id: 'owner-1', displayName: 'Owner', timezone: 'UTC'),
              ),
            ),
          ),
          groupDetailNotifierProvider(
            'group-1',
          ).overrideWith(_FailingGroupDetailNotifier.new),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupCoordinationScreen(groupId: 'group-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Server error'), findsOneWidget);
    expect(find.text('Add Window'), findsNothing);
  });

  testWidgets(
    'session status dropdown shows the selected row with a checkmark in the open menu',
    (tester) async {
      final notifier = _FakeCoordinationNotifier(
        GroupCoordinationState(
          sessions: [
            GroupSession(
              id: 'session-1',
              groupId: 'group-1',
              proposedBy: 'owner-1',
              proposedByDisplayName: 'Owner',
              title: 'Valheim Night',
              game: 'Valheim',
              startsAt: DateTime.utc(2026, 6, 6, 20),
              status: 'proposed',
              createdAt: DateTime.utc(2026, 6, 5, 10),
            ),
          ],
        ),
      );
      final authNotifier = _FakeAuthNotifier(
        const AuthState.authenticated(
          User(id: 'owner-1', displayName: 'Owner', timezone: 'UTC'),
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
            memberCount: 1,
          ),
          members: [
            GroupMember(
              id: 'membership-owner',
              userId: 'owner-1',
              displayName: 'Owner',
              role: 'owner',
            ),
          ],
          currentUserId: 'owner-1',
          currentUserRole: 'owner',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupCoordinationNotifierProvider(
              'group-1',
            ).overrideWith(() => notifier),
            authNotifierProvider.overrideWith(() => authNotifier),
            groupDetailNotifierProvider(
              'group-1',
            ).overrideWith(() => detailNotifier),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: GroupCoordinationScreen(groupId: 'group-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _openSessionEditMenu(tester);
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    },
  );
}
