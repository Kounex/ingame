import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/networking/websocket_client.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/shared/providers/presence_provider.dart';
import 'package:ingame/shared/widgets/status_indicator.dart';

class _RecordingWebSocketClient extends WebSocketClient {
  _RecordingWebSocketClient()
    : _eventController = StreamController<dynamic>.broadcast(),
      super(
        baseUrl: 'ws://example.test/api/v1/ws',
        getAccessToken: () async => 'token',
      );

  final StreamController<dynamic> _eventController;
  final sentMessages = <Map<String, dynamic>>[];

  @override
  Stream<dynamic> get events => _eventController.stream;

  @override
  bool get isConnected => true;

  @override
  void send(Map<String, dynamic> message) {
    sentMessages.add(message);
  }

  void emit(dynamic event) {
    _eventController.add(event);
  }

  @override
  void dispose() {
    _eventController.close();
    super.dispose();
  }
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  Future<AuthState> build() async => _initialState;
}

void main() {
  test('presence snapshot stores connection and ready metadata per member', () async {
    final wsClient = _RecordingWebSocketClient();
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _FakeAuthNotifier(
            const AuthState.authenticated(
              User(id: 'user-1', displayName: 'Me', timezone: 'UTC'),
            ),
          ),
        ),
        websocketClientProvider.overrideWithValue(wsClient),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.future);
    container.read(presenceNotifierProvider);

    final expiresAt =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600).toString();
    wsClient.emit({
      'type': 'presence_snapshot',
      'groups': [
        {
          'group_id': 'group-1',
          'members': [
            {
              'user_id': 'user-2',
              'connection': 'online',
              'ready': true,
              'ready_since': '100',
              'ready_expires_at': expiresAt,
            },
          ],
        },
      ],
    });
    await Future<void>.delayed(Duration.zero);

    final status = container.read(
      groupMemberStatusProvider((groupId: 'group-1', userId: 'user-2')),
    );
    expect(status, UserStatus.ready);
  });

  test('connection_changed away and active update derived status', () async {
    final wsClient = _RecordingWebSocketClient();
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _FakeAuthNotifier(
            const AuthState.authenticated(
              User(id: 'user-1', displayName: 'Me', timezone: 'UTC'),
            ),
          ),
        ),
        websocketClientProvider.overrideWithValue(wsClient),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.future);
    container.read(presenceNotifierProvider);

    wsClient.emit({
      'type': 'presence_snapshot',
      'groups': [
        {
          'group_id': 'group-1',
          'members': [
            {'user_id': 'user-2', 'connection': 'online', 'ready': false},
          ],
        },
      ],
    });
    await Future<void>.delayed(Duration.zero);

    wsClient.emit({
      'type': 'connection_changed',
      'group_id': 'group-1',
      'user_id': 'user-2',
      'connection': 'away',
    });
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(
        groupMemberStatusProvider((groupId: 'group-1', userId: 'user-2')),
      ),
      UserStatus.away,
    );

    wsClient.emit({
      'type': 'connection_changed',
      'group_id': 'group-1',
      'user_id': 'user-2',
      'connection': 'online',
    });
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(
        groupMemberStatusProvider((groupId: 'group-1', userId: 'user-2')),
      ),
      UserStatus.online,
    );
  });

  test('ready expiry clears ready state locally', () async {
    final wsClient = _RecordingWebSocketClient();
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _FakeAuthNotifier(
            const AuthState.authenticated(
              User(id: 'user-1', displayName: 'Me', timezone: 'UTC'),
            ),
          ),
        ),
        websocketClientProvider.overrideWithValue(wsClient),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.future);
    final notifier = container.read(presenceNotifierProvider.notifier);
    container.read(presenceNotifierProvider);

    wsClient.emit({
      'type': 'user_online',
      'group_id': 'group-1',
      'user_id': 'user-2',
    });
    await Future<void>.delayed(Duration.zero);

    wsClient.emit({
      'type': 'ready_changed',
      'group_id': 'group-1',
      'user_id': 'user-2',
      'ready': true,
      'ready_since': '100',
      'ready_expires_at':
          (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600).toString(),
    });
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(
        groupMemberStatusProvider((groupId: 'group-1', userId: 'user-2')),
      ),
      UserStatus.ready,
    );

    notifier.handleReadyExpiry(
      groupId: 'group-1',
      userId: 'user-2',
    );

    expect(
      container.read(
        groupMemberStatusProvider((groupId: 'group-1', userId: 'user-2')),
      ),
      UserStatus.online,
    );
  });

  test('user_offline marks member offline', () async {
    final wsClient = _RecordingWebSocketClient();
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _FakeAuthNotifier(
            const AuthState.authenticated(
              User(id: 'user-1', displayName: 'Me', timezone: 'UTC'),
            ),
          ),
        ),
        websocketClientProvider.overrideWithValue(wsClient),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.future);
    container.read(presenceNotifierProvider);

    wsClient.emit({
      'type': 'presence_snapshot',
      'groups': [
        {
          'group_id': 'group-1',
          'members': [
            {'user_id': 'user-2', 'connection': 'online', 'ready': false},
          ],
        },
      ],
    });
    await Future<void>.delayed(Duration.zero);

    wsClient.emit({
      'type': 'user_offline',
      'group_id': 'group-1',
      'user_id': 'user-2',
    });
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(
        groupMemberStatusProvider((groupId: 'group-1', userId: 'user-2')),
      ),
      UserStatus.offline,
    );
  });

  test('ready_changed does not flip offline member back to online', () async {
    final wsClient = _RecordingWebSocketClient();
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _FakeAuthNotifier(
            const AuthState.authenticated(
              User(id: 'user-1', displayName: 'Me', timezone: 'UTC'),
            ),
          ),
        ),
        websocketClientProvider.overrideWithValue(wsClient),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.future);
    container.read(presenceNotifierProvider);

    wsClient.emit({
      'type': 'user_offline',
      'group_id': 'group-1',
      'user_id': 'user-2',
    });
    await Future<void>.delayed(Duration.zero);

    wsClient.emit({
      'type': 'ready_changed',
      'group_id': 'group-1',
      'user_id': 'user-2',
      'ready': true,
      'ready_since': '100',
      'ready_expires_at':
          (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600).toString(),
    });
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(
        groupMemberStatusProvider((groupId: 'group-1', userId: 'user-2')),
      ),
      UserStatus.offline,
    );
  });

  test('deriveMemberStatus prioritizes offline over ready and away', () {
    expect(
      deriveMemberStatus(
        const MemberPresenceState(connection: 'offline', ready: true),
      ),
      UserStatus.offline,
    );
    expect(
      deriveMemberStatus(
        const MemberPresenceState(connection: 'away', ready: true),
      ),
      UserStatus.away,
    );
    expect(
      deriveMemberStatus(
        const MemberPresenceState(connection: 'online', ready: true),
      ),
      UserStatus.ready,
    );
    expect(
      deriveMemberStatus(
        const MemberPresenceState(connection: 'online', ready: false),
      ),
      UserStatus.online,
    );
  });

  test('toggleReady sends ready_toggle command', () {
    final wsClient = _RecordingWebSocketClient();
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _FakeAuthNotifier(
            const AuthState.authenticated(
              User(id: 'user-1', displayName: 'Me', timezone: 'UTC'),
            ),
          ),
        ),
        websocketClientProvider.overrideWithValue(wsClient),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(presenceNotifierProvider.notifier)
        .toggleReady(groupId: 'group-1', ready: true);

    expect(wsClient.sentMessages.single, {
      'type': 'ready_toggle',
      'group_id': 'group-1',
      'ready': true,
    });
  });
}
