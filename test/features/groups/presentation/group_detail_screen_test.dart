import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/networking/websocket_client.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/features/groups/domain/coordination_model.dart';
import 'package:ingame/features/groups/domain/group_model.dart';
import 'package:ingame/features/groups/domain/membership_model.dart';
import 'package:ingame/features/groups/presentation/providers/group_coordination_provider.dart';
import 'package:ingame/features/groups/presentation/providers/group_detail_provider.dart';
import 'package:ingame/features/groups/presentation/screens/group_detail_screen.dart';
import 'package:ingame/l10n/app_localizations.dart';
import 'package:ingame/shared/providers/presence_provider.dart';
import 'package:ingame/shared/services/app_haptics.dart';
import 'package:ingame/shared/widgets/status_indicator.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => const AuthState.authenticated(
    User(id: 'owner-1', displayName: 'Owner', timezone: 'UTC'),
  );
}

class _FakeGroupDetailNotifier extends GroupDetailNotifier {
  _FakeGroupDetailNotifier(this._state) : super('group-1');

  final GroupDetailState _state;

  @override
  Future<GroupDetailState> build() async => _state;
}

class _FakeCoordinationNotifier extends GroupCoordinationNotifier {
  _FakeCoordinationNotifier(this._state) : super('group-1');

  final GroupCoordinationState _state;

  @override
  Future<GroupCoordinationState> build() async => _state;
}

class _RecordingPresenceNotifier extends PresenceNotifier {
  bool? lastReadyValue;
  String? lastGroupId;

  @override
  Map<String, Map<String, MemberPresenceState>> build() => const {};

  @override
  bool toggleReady({required String groupId, required bool ready}) {
    lastGroupId = groupId;
    lastReadyValue = ready;
    return true;
  }
}

class _FakeWebSocketClient extends WebSocketClient {
  _FakeWebSocketClient()
    : _stateController = StreamController<WebSocketConnectionState>.broadcast(),
      super(
        baseUrl: 'ws://example.test/api/v1/ws',
        getAccessToken: () async => 'token',
      );

  final StreamController<WebSocketConnectionState> _stateController;

  @override
  WebSocketConnectionState get connectionState =>
      WebSocketConnectionState.connected;

  @override
  bool get isConnected => true;

  @override
  Stream<WebSocketConnectionState> get connectionStateStream =>
      _stateController.stream;

  @override
  void dispose() {
    _stateController.close();
    super.dispose();
  }
}

void main() {
  testWidgets(
    'members section stays anchored near the bottom on tall viewports',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 1400);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
            websocketClientProvider.overrideWithValue(_FakeWebSocketClient()),
            groupDetailNotifierProvider('group-1').overrideWith(
              () => _FakeGroupDetailNotifier(
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
                  currentUserId: 'owner-1',
                  currentUserRole: 'owner',
                ),
              ),
            ),
            groupCoordinationNotifierProvider('group-1').overrideWith(
              () => _FakeCoordinationNotifier(const GroupCoordinationState()),
            ),
            groupMemberStatusProvider.overrideWith(
              (ref, key) => UserStatus.online,
            ),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: GroupDetailScreen(groupId: 'group-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final membersSectionTop = tester
          .getTopLeft(find.text(l10n.groupDetailSectionMembers))
          .dy;
      final viewportHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;

      expect(membersSectionTop, greaterThan(viewportHeight * 0.55));
    },
  );

  testWidgets('turning ready on asks for confirmation first', (tester) async {
    final presenceNotifier = _RecordingPresenceNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          presenceNotifierProvider.overrideWith(() => presenceNotifier),
          websocketClientProvider.overrideWithValue(_FakeWebSocketClient()),
          groupDetailNotifierProvider('group-1').overrideWith(
            () => _FakeGroupDetailNotifier(
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
                ],
                currentUserId: 'owner-1',
                currentUserRole: 'owner',
              ),
            ),
          ),
          groupCoordinationNotifierProvider('group-1').overrideWith(
            () => _FakeCoordinationNotifier(const GroupCoordinationState()),
          ),
          groupMemberStatusProvider.overrideWith(
            (ref, key) => UserStatus.online,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupDetailScreen(groupId: 'group-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(find.text('Turn on ready status?'), findsOneWidget);
    expect(presenceNotifier.lastReadyValue, isNull);

    await tester.tap(find.widgetWithText(TextButton, 'Turn On'));
    await tester.pumpAndSettle();

    expect(presenceNotifier.lastGroupId, 'group-1');
    expect(presenceNotifier.lastReadyValue, isTrue);
  });

  testWidgets('group action menu triggers haptics on open and selection', (
    tester,
  ) async {
    var selectionHaptics = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          websocketClientProvider.overrideWithValue(_FakeWebSocketClient()),
          appHapticsProvider.overrideWithValue(
            AppHaptics(
              isWeb: false,
              platform: TargetPlatform.android,
              selectionCallback: () async => selectionHaptics++,
            ),
          ),
          groupDetailNotifierProvider('group-1').overrideWith(
            () => _FakeGroupDetailNotifier(
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
                ],
                currentUserId: 'owner-1',
                currentUserRole: 'owner',
              ),
            ),
          ),
          groupCoordinationNotifierProvider('group-1').overrideWith(
            () => _FakeCoordinationNotifier(const GroupCoordinationState()),
          ),
          groupMemberStatusProvider.overrideWith(
            (ref, key) => UserStatus.online,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupDetailScreen(groupId: 'group-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(selectionHaptics, 1);

    await tester.tap(find.text('Leave Group'));
    await tester.pumpAndSettle();

    expect(selectionHaptics, 2);
  });

  testWidgets('coordination card skips past and cancelled sessions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          websocketClientProvider.overrideWithValue(_FakeWebSocketClient()),
          groupDetailNotifierProvider('group-1').overrideWith(
            () => _FakeGroupDetailNotifier(
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
                ],
                currentUserId: 'owner-1',
                currentUserRole: 'owner',
              ),
            ),
          ),
          groupCoordinationNotifierProvider('group-1').overrideWith(
            () => _FakeCoordinationNotifier(
              GroupCoordinationState(
                sessions: [
                  GroupSession(
                    id: 'session-old',
                    groupId: 'group-1',
                    proposedBy: 'owner-1',
                    proposedByDisplayName: 'Owner',
                    title: 'Old Session',
                    startsAt: DateTime.utc(2025, 1, 1, 20),
                    status: 'proposed',
                    createdAt: DateTime.utc(2024, 12, 31, 10),
                  ),
                  GroupSession(
                    id: 'session-cancelled',
                    groupId: 'group-1',
                    proposedBy: 'owner-1',
                    proposedByDisplayName: 'Owner',
                    title: 'Cancelled Session',
                    startsAt: DateTime.utc(2099, 1, 2, 20),
                    status: 'cancelled',
                    createdAt: DateTime.utc(2099, 1, 1, 10),
                  ),
                  GroupSession(
                    id: 'session-next',
                    groupId: 'group-1',
                    proposedBy: 'owner-1',
                    proposedByDisplayName: 'Owner',
                    title: 'Future Session',
                    startsAt: DateTime.utc(2099, 1, 3, 20),
                    status: 'proposed',
                    createdAt: DateTime.utc(2099, 1, 1, 10),
                  ),
                ],
              ),
            ),
          ),
          groupMemberStatusProvider.overrideWith(
            (ref, key) => UserStatus.online,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupDetailScreen(groupId: 'group-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Future Session'), findsOneWidget);
    expect(find.textContaining('Old Session'), findsNothing);
    expect(find.textContaining('Cancelled Session'), findsNothing);
  });

  testWidgets('coordination card counts only upcoming ready windows', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          websocketClientProvider.overrideWithValue(_FakeWebSocketClient()),
          groupDetailNotifierProvider('group-1').overrideWith(
            () => _FakeGroupDetailNotifier(
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
                ],
                currentUserId: 'owner-1',
                currentUserRole: 'owner',
              ),
            ),
          ),
          groupCoordinationNotifierProvider('group-1').overrideWith(
            () => _FakeCoordinationNotifier(
              GroupCoordinationState(
                windows: [
                  ScheduledReadyWindow(
                    id: 'window-past-1',
                    groupId: 'group-1',
                    userId: 'owner-1',
                    displayName: 'Owner',
                    startsAt: DateTime.utc(2020, 1, 1, 18),
                    endsAt: DateTime.utc(2020, 1, 1, 20),
                    source: 'manual',
                    createdAt: DateTime.utc(2019, 12, 31, 10),
                  ),
                  ScheduledReadyWindow(
                    id: 'window-past-2',
                    groupId: 'group-1',
                    userId: 'owner-1',
                    displayName: 'Owner',
                    startsAt: DateTime.utc(2020, 1, 2, 18),
                    endsAt: DateTime.utc(2020, 1, 2, 20),
                    source: 'manual',
                    createdAt: DateTime.utc(2020, 1, 1, 10),
                  ),
                  ScheduledReadyWindow(
                    id: 'window-future-1',
                    groupId: 'group-1',
                    userId: 'owner-1',
                    displayName: 'Owner',
                    startsAt: DateTime.utc(2099, 1, 3, 18),
                    endsAt: DateTime.utc(2099, 1, 3, 20),
                    source: 'manual',
                    createdAt: DateTime.utc(2099, 1, 1, 10),
                  ),
                  ScheduledReadyWindow(
                    id: 'window-future-2',
                    groupId: 'group-1',
                    userId: 'owner-1',
                    displayName: 'Owner',
                    startsAt: DateTime.utc(2099, 1, 4, 18),
                    endsAt: DateTime.utc(2099, 1, 4, 20),
                    source: 'manual',
                    createdAt: DateTime.utc(2099, 1, 1, 10),
                  ),
                ],
              ),
            ),
          ),
          groupMemberStatusProvider.overrideWith(
            (ref, key) => UserStatus.online,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupDetailScreen(groupId: 'group-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 windows'), findsOneWidget);
    expect(find.text('4 windows'), findsNothing);
  });
}
