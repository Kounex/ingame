import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/networking/websocket_client.dart';
import 'package:ingame/features/groups/data/group_coordination_repository.dart';
import 'package:ingame/features/groups/domain/coordination_model.dart';
import 'package:ingame/features/groups/presentation/providers/group_coordination_provider.dart';

class _FakeCoordinationRepository extends GroupCoordinationRepository {
  _FakeCoordinationRepository()
    : windows = [
        GroupCoordinationFixtures.window(
          id: 'window-1',
          displayName: 'Owner',
        ),
      ],
      sessions = [
        GroupCoordinationFixtures.session(
          id: 'session-1',
          title: 'Raid Night',
          rsvps: [GroupCoordinationFixtures.rsvp()],
        ),
      ],
      activity = [
        GroupCoordinationFixtures.activity(id: 'activity-1'),
      ],
      super(dio: Dio());

  final List<ScheduledReadyWindow> windows;
  final List<GroupSession> sessions;
  final List<GroupActivityEvent> activity;
  SessionRsvp? rsvpResponse;

  @override
  Future<List<ScheduledReadyWindow>> listScheduledReady(String groupId) async =>
      List.of(windows);

  @override
  Future<List<GroupSession>> listSessions(String groupId) async => List.of(sessions);

  @override
  Future<List<GroupActivityEvent>> listActivity(String groupId) async =>
      List.of(activity);

  @override
  Future<SessionRsvp> rsvpToSession(
    String groupId,
    String sessionId,
    String responseValue,
  ) async {
    rsvpResponse = GroupCoordinationFixtures.rsvp(response: responseValue);
    return rsvpResponse!;
  }
}

class _HangingCoordinationRepository extends _FakeCoordinationRepository {
  @override
  Future<List<GroupActivityEvent>> listActivity(String groupId) =>
      Completer<List<GroupActivityEvent>>().future;
}

class _MissingActivityCoordinationRepository extends _FakeCoordinationRepository {
  @override
  Future<List<GroupActivityEvent>> listActivity(String groupId) {
    final request = RequestOptions(
      path: '/groups/$groupId/activity',
    );
    throw DioException(
      requestOptions: request,
      response: Response(
        requestOptions: request,
        statusCode: 404,
        data: const {'detail': 'Not found'},
      ),
      type: DioExceptionType.badResponse,
    );
  }
}

class _RecordingWebSocketClient extends WebSocketClient {
  _RecordingWebSocketClient()
    : _eventController = StreamController<dynamic>.broadcast(),
      super(
        baseUrl: 'ws://example.test/api/v1/ws',
        getAccessToken: () async => 'token',
      );

  final StreamController<dynamic> _eventController;

  @override
  Stream<dynamic> get events => _eventController.stream;

  void emit(dynamic event) => _eventController.add(event);

  @override
  void dispose() {
    _eventController.close();
    super.dispose();
  }
}

class GroupCoordinationFixtures {
  static ScheduledReadyWindow window({
    String id = 'window-1',
    String displayName = 'Owner',
  }) {
    return ScheduledReadyWindow(
      id: id,
      groupId: 'group-1',
      userId: 'owner-1',
      displayName: displayName,
      startsAt: DateTime.utc(2026, 6, 6, 20),
      endsAt: DateTime.utc(2026, 6, 6, 22),
      source: 'manual',
      createdAt: DateTime.utc(2026, 6, 5, 10),
    );
  }

  static SessionRsvp rsvp({
    String id = 'rsvp-1',
    String response = 'maybe',
  }) {
    return SessionRsvp(
      id: id,
      sessionId: 'session-1',
      userId: 'member-1',
      displayName: 'Member',
      response: response,
      updatedAt: DateTime.utc(2026, 6, 5, 10, 5),
    );
  }

  static GroupSession session({
    String id = 'session-1',
    String title = 'Raid Night',
    List<SessionRsvp> rsvps = const [],
  }) {
    return GroupSession(
      id: id,
      groupId: 'group-1',
      proposedBy: 'owner-1',
      proposedByDisplayName: 'Owner',
      title: title,
      game: 'Valheim',
      startsAt: DateTime.utc(2026, 6, 6, 20),
      status: 'proposed',
      createdAt: DateTime.utc(2026, 6, 5, 10),
      rsvps: rsvps,
    );
  }

  static GroupActivityEvent activity({String id = 'activity-1'}) {
    return GroupActivityEvent(
      id: id,
      groupId: 'group-1',
      actorUserId: 'owner-1',
      actorDisplayName: 'Owner',
      type: 'session_proposed',
      message: 'Owner proposed a session',
      sessionId: 'session-1',
      createdAt: DateTime.utc(2026, 6, 5, 10),
    );
  }
}

void main() {
  test('bootstrap loads windows, sessions, and activity', () async {
    final repository = _FakeCoordinationRepository();
    final wsClient = _RecordingWebSocketClient();
    final container = ProviderContainer(
      overrides: [
        groupCoordinationRepositoryProvider.overrideWithValue(repository),
        websocketClientProvider.overrideWithValue(wsClient),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(groupCoordinationNotifierProvider('group-1').future);

    expect(state.windows.map((item) => item.id), ['window-1']);
    expect(state.sessions.map((item) => item.id), ['session-1']);
    expect(state.activity.map((item) => item.id), ['activity-1']);
  });

  test('scheduled ready and activity websocket events update state', () async {
    final repository = _FakeCoordinationRepository();
    final wsClient = _RecordingWebSocketClient();
    final container = ProviderContainer(
      overrides: [
        groupCoordinationRepositoryProvider.overrideWithValue(repository),
        websocketClientProvider.overrideWithValue(wsClient),
      ],
    );
    addTearDown(container.dispose);

    await container.read(groupCoordinationNotifierProvider('group-1').future);

    wsClient.emit({
      'type': 'scheduled_ready_updated',
      'group_id': 'group-1',
      'window': {
        'id': 'window-2',
        'group_id': 'group-1',
        'user_id': 'member-1',
        'display_name': 'Member',
        'starts_at': '2026-06-07T18:00:00Z',
        'ends_at': '2026-06-07T20:00:00Z',
        'source': 'manual',
        'created_at': '2026-06-05T10:10:00Z',
        'updated_at': null,
      },
    });
    wsClient.emit({
      'type': 'activity_recorded',
      'group_id': 'group-1',
      'activity': {
        'id': 'activity-2',
        'group_id': 'group-1',
        'actor_user_id': 'member-1',
        'actor_display_name': 'Member',
        'type': 'scheduled_ready_updated',
        'message': 'Member updated their ready window',
        'session_id': null,
        'scheduled_ready_window_id': 'window-2',
        'created_at': '2026-06-05T10:10:00Z',
      },
    });
    await Future<void>.delayed(Duration.zero);

    final state = container.read(groupCoordinationNotifierProvider('group-1')).value!;
    expect(state.windows.map((item) => item.id), contains('window-2'));
    expect(state.activity.first.id, 'activity-2');
  });

  test('session rsvp websocket event updates the matching session', () async {
    final repository = _FakeCoordinationRepository();
    final wsClient = _RecordingWebSocketClient();
    final container = ProviderContainer(
      overrides: [
        groupCoordinationRepositoryProvider.overrideWithValue(repository),
        websocketClientProvider.overrideWithValue(wsClient),
      ],
    );
    addTearDown(container.dispose);

    await container.read(groupCoordinationNotifierProvider('group-1').future);

    wsClient.emit({
      'type': 'session_rsvp_updated',
      'group_id': 'group-1',
      'rsvp': {
        'id': 'rsvp-1',
        'session_id': 'session-1',
        'user_id': 'member-1',
        'display_name': 'Member',
        'response': 'in',
        'updated_at': '2026-06-05T10:12:00Z',
      },
    });
    await Future<void>.delayed(Duration.zero);

    final state = container.read(groupCoordinationNotifierProvider('group-1')).value!;
    expect(state.sessions.single.rsvps.single.response, 'in');
  });

  test('rsvp mutation updates session locally without entering loading', () async {
    final repository = _FakeCoordinationRepository();
    final wsClient = _RecordingWebSocketClient();
    final container = ProviderContainer(
      overrides: [
        groupCoordinationRepositoryProvider.overrideWithValue(repository),
        websocketClientProvider.overrideWithValue(wsClient),
      ],
    );
    addTearDown(container.dispose);

    await container.read(groupCoordinationNotifierProvider('group-1').future);

    final snapshots = <AsyncValue<GroupCoordinationState>>[];
    final sub = container.listen<AsyncValue<GroupCoordinationState>>(
      groupCoordinationNotifierProvider('group-1'),
      (_, next) => snapshots.add(next),
      fireImmediately: false,
    );
    addTearDown(sub.close);

    await container
        .read(groupCoordinationNotifierProvider('group-1').notifier)
        .rsvpToSession('session-1', 'in');

    final state = container.read(groupCoordinationNotifierProvider('group-1')).value!;
    expect(state.sessions.single.rsvps.single.response, 'in');
    expect(snapshots.any((value) => value.isLoading), isFalse);
  });

  test('bootstrap fails fast when one coordination request never resolves', () async {
    final repository = _HangingCoordinationRepository();
    final wsClient = _RecordingWebSocketClient();
    final container = ProviderContainer(
      overrides: [
        groupCoordinationRepositoryProvider.overrideWithValue(repository),
        websocketClientProvider.overrideWithValue(wsClient),
        groupCoordinationLoadTimeoutProvider.overrideWithValue(
          const Duration(milliseconds: 20),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(groupCoordinationNotifierProvider('group-1'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final state = container.read(groupCoordinationNotifierProvider('group-1'));
    expect(state.hasError, isTrue);
    expect(state.error, isA<TimeoutException>());
  });

  test('bootstrap tolerates missing activity feed and keeps other coordination data', () async {
    final repository = _MissingActivityCoordinationRepository();
    final wsClient = _RecordingWebSocketClient();
    final container = ProviderContainer(
      overrides: [
        groupCoordinationRepositoryProvider.overrideWithValue(repository),
        websocketClientProvider.overrideWithValue(wsClient),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(groupCoordinationNotifierProvider('group-1').future);

    expect(state.windows.map((item) => item.id), ['window-1']);
    expect(state.sessions.map((item) => item.id), ['session-1']);
    expect(state.activity, isEmpty);
  });
}
