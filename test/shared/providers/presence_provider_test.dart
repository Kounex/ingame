import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/networking/websocket_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/shared/providers/presence_provider.dart';
import 'package:ingame/shared/providers/websocket_provider.dart';
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
  bool get isConnected => connectionState == WebSocketConnectionState.connected;

  @override
  WebSocketConnectionState connectionState = WebSocketConnectionState.connected;

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

class _ControllableAuthNotifier extends AuthNotifier {
  _ControllableAuthNotifier(this._state);

  AuthState _state;

  @override
  Future<AuthState> build() async => _state;

  void setAuthState(AuthState next) {
    _state = next;
    state = AsyncValue.data(next);
  }
}

void _bootstrapAppRealtimeProviders(ProviderContainer container) {
  container.read(websocketConnectionProvider);
  container.read(presenceNotifierProvider);
}

class _BootstrapFakeWebSocketChannel implements WebSocketChannel {
  _BootstrapFakeWebSocketChannel()
    : _controller = StreamController<dynamic>.broadcast(),
      _sink = _BootstrapFakeWebSocketSink();

  final StreamController<dynamic> _controller;
  final _BootstrapFakeWebSocketSink _sink;

  @override
  Stream get stream => _controller.stream;

  @override
  WebSocketSink get sink {
    _sink.onClose = _controller.close;
    return _sink;
  }

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  Future<void> get ready async {}

  void emitServerMessage(String message) {
    _controller.add(message);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BootstrapFakeWebSocketSink implements WebSocketSink {
  void Function()? onClose;

  @override
  Future<dynamic> get done async => null;

  @override
  void add(message) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream stream) async {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    onClose?.call();
  }
}

void main() {
  test(
    'login flow keeps self online after websocket presence snapshot',
    () async {
      const selfUserId = 'user-self';
      const groupId = 'group-1';
      final channels = <_BootstrapFakeWebSocketChannel>[];
      final wsClient = WebSocketClient(
        baseUrl: 'ws://example.test/api/v1/ws',
        getAccessToken: () async => 'token',
        createChannel: (uri) {
          final channel = _BootstrapFakeWebSocketChannel();
          channels.add(channel);
          return channel;
        },
      );
      addTearDown(wsClient.dispose);

      final authNotifier = _ControllableAuthNotifier(
        const AuthState.unauthenticated(),
      );
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(() => authNotifier),
          websocketClientProvider.overrideWithValue(wsClient),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);

      authNotifier.setAuthState(
        const AuthState.authenticated(
          User(id: selfUserId, displayName: 'Me', timezone: 'UTC'),
        ),
      );
      _bootstrapAppRealtimeProviders(container);

      final deadline = DateTime.now().add(const Duration(seconds: 1));
      while (!wsClient.isConnected && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(wsClient.isConnected, isTrue, reason: 'websocket should connect');

      channels.last.emitServerMessage(
        jsonEncode({
          'type': 'presence_snapshot',
          'groups': [
            {
              'group_id': groupId,
              'members': [
                {'user_id': selfUserId, 'connection': 'online', 'ready': false},
              ],
            },
          ],
        }),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        container
            .read(presenceNotifierProvider)[groupId]?[selfUserId]
            ?.connection,
        'online',
      );
      expect(
        container.read(
          groupMemberStatusProvider((groupId: groupId, userId: selfUserId)),
        ),
        UserStatus.online,
      );
    },
  );

  test(
    'fresh login through loading shows self online after websocket snapshot',
    () async {
      const selfUserId = 'user-self';
      const groupId = 'group-1';
      final channels = <_BootstrapFakeWebSocketChannel>[];
      final wsClient = WebSocketClient(
        baseUrl: 'ws://example.test/api/v1/ws',
        getAccessToken: () async => 'token',
        createChannel: (uri) {
          final channel = _BootstrapFakeWebSocketChannel();
          channels.add(channel);
          return channel;
        },
      );
      addTearDown(wsClient.dispose);

      final authNotifier = _ControllableAuthNotifier(
        const AuthState.unauthenticated(),
      );
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(() => authNotifier),
          websocketClientProvider.overrideWithValue(wsClient),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);
      _bootstrapAppRealtimeProviders(container);

      authNotifier.setAuthState(const AuthState.loading());
      _bootstrapAppRealtimeProviders(container);

      authNotifier.setAuthState(
        const AuthState.authenticated(
          User(id: selfUserId, displayName: 'Me', timezone: 'UTC'),
        ),
      );
      _bootstrapAppRealtimeProviders(container);

      final deadline = DateTime.now().add(const Duration(seconds: 1));
      while (!wsClient.isConnected && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      channels.last.emitServerMessage(
        jsonEncode({
          'type': 'presence_snapshot',
          'groups': [
            {
              'group_id': groupId,
              'members': [
                {'user_id': selfUserId, 'connection': 'online', 'ready': false},
              ],
            },
          ],
        }),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(
          groupMemberStatusProvider((groupId: groupId, userId: selfUserId)),
        ),
        UserStatus.online,
      );
    },
  );

  test(
    'login loading transition does not permanently clear self presence after snapshot',
    () async {
      const selfUserId = 'user-self';
      const groupId = 'group-1';
      final channels = <_BootstrapFakeWebSocketChannel>[];
      final wsClient = WebSocketClient(
        baseUrl: 'ws://example.test/api/v1/ws',
        getAccessToken: () async => 'token',
        createChannel: (uri) {
          final channel = _BootstrapFakeWebSocketChannel();
          channels.add(channel);
          return channel;
        },
      );
      addTearDown(wsClient.dispose);

      final authNotifier = _ControllableAuthNotifier(
        const AuthState.unauthenticated(),
      );
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(() => authNotifier),
          websocketClientProvider.overrideWithValue(wsClient),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);
      _bootstrapAppRealtimeProviders(container);

      authNotifier.setAuthState(
        const AuthState.authenticated(
          User(id: selfUserId, displayName: 'Me', timezone: 'UTC'),
        ),
      );
      _bootstrapAppRealtimeProviders(container);

      final deadline = DateTime.now().add(const Duration(seconds: 1));
      while (!wsClient.isConnected && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      channels.last.emitServerMessage(
        jsonEncode({
          'type': 'presence_snapshot',
          'groups': [
            {
              'group_id': groupId,
              'members': [
                {'user_id': selfUserId, 'connection': 'online', 'ready': false},
              ],
            },
          ],
        }),
      );
      await Future<void>.delayed(Duration.zero);

      authNotifier.setAuthState(const AuthState.loading());
      _bootstrapAppRealtimeProviders(container);

      authNotifier.setAuthState(
        const AuthState.authenticated(
          User(id: selfUserId, displayName: 'Me', timezone: 'UTC'),
        ),
      );
      _bootstrapAppRealtimeProviders(container);

      expect(
        container.read(
          groupMemberStatusProvider((groupId: groupId, userId: selfUserId)),
        ),
        UserStatus.online,
      );
    },
  );

  test(
    'presence rebuild after snapshot preserves self online when cache exists',
    () async {
      const selfUserId = 'user-self';
      const groupId = 'group-1';
      final wsClient = _RecordingWebSocketClient();
      final authNotifier = _ControllableAuthNotifier(
        const AuthState.authenticated(
          User(id: selfUserId, displayName: 'Me', timezone: 'UTC'),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(() => authNotifier),
          websocketClientProvider.overrideWithValue(wsClient),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);
      _bootstrapAppRealtimeProviders(container);

      wsClient.emit({
        'type': 'presence_snapshot',
        'groups': [
          {
            'group_id': groupId,
            'members': [
              {'user_id': selfUserId, 'connection': 'online', 'ready': false},
            ],
          },
        ],
      });
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(
          groupMemberStatusProvider((groupId: groupId, userId: selfUserId)),
        ),
        UserStatus.online,
      );

      authNotifier.setAuthState(const AuthState.loading());
      _bootstrapAppRealtimeProviders(container);

      authNotifier.setAuthState(
        const AuthState.authenticated(
          User(id: selfUserId, displayName: 'Me', timezone: 'UTC'),
        ),
      );
      _bootstrapAppRealtimeProviders(container);

      expect(
        container.read(
          groupMemberStatusProvider((groupId: groupId, userId: selfUserId)),
        ),
        UserStatus.online,
        reason:
            'login loading must not permanently clear hydrated self presence',
      );
    },
  );

  test(
    'legacy presence snapshot with statuses hydrates self as online',
    () async {
      const selfUserId = 'user-self';
      const groupId = 'group-1';
      final wsClient = _RecordingWebSocketClient();
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(
              const AuthState.authenticated(
                User(id: selfUserId, displayName: 'Me', timezone: 'UTC'),
              ),
            ),
          ),
          websocketClientProvider.overrideWithValue(wsClient),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);
      _bootstrapAppRealtimeProviders(container);

      wsClient.emit({
        'type': 'presence_snapshot',
        'groups': [
          {
            'group_id': groupId,
            'online_user_ids': [selfUserId],
            'statuses': [
              {
                'user_id': selfUserId,
                'state': 'online',
                'game': null,
                'since': '1780349375',
              },
            ],
          },
        ],
      });
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(
          groupMemberStatusProvider((groupId: groupId, userId: selfUserId)),
        ),
        UserStatus.online,
      );
    },
  );

  test(
    'presence hydrates from snapshot emitted on connect before listener attaches',
    () async {
      final channels = <_BootstrapFakeWebSocketChannel>[];
      final wsClient = WebSocketClient(
        baseUrl: 'ws://example.test/api/v1/ws',
        getAccessToken: () async => 'token',
        createChannel: (uri) {
          final channel = _BootstrapFakeWebSocketChannel();
          channels.add(channel);
          return channel;
        },
      );
      addTearDown(wsClient.dispose);

      await wsClient.connect();
      channels.single.emitServerMessage(
        jsonEncode({
          'type': 'presence_snapshot',
          'groups': [
            {
              'group_id': 'group-1',
              'members': [
                {'user_id': 'user-1', 'connection': 'online', 'ready': false},
                {'user_id': 'user-2', 'connection': 'online', 'ready': false},
              ],
            },
          ],
        }),
      );
      await Future<void>.delayed(Duration.zero);

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
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(
          groupMemberStatusProvider((groupId: 'group-1', userId: 'user-1')),
        ),
        UserStatus.online,
      );
      expect(
        container.read(
          groupMemberStatusProvider((groupId: 'group-1', userId: 'user-2')),
        ),
        UserStatus.online,
      );
    },
  );

  test(
    'presence snapshot stores connection and ready metadata per member',
    () async {
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

      final expiresAt = (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600)
          .toString();
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
    },
  );

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
      'ready_expires_at': (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600)
          .toString(),
    });
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(
        groupMemberStatusProvider((groupId: 'group-1', userId: 'user-2')),
      ),
      UserStatus.ready,
    );

    notifier.handleReadyExpiry(groupId: 'group-1', userId: 'user-2');

    expect(
      container.read(
        groupMemberStatusProvider((groupId: 'group-1', userId: 'user-2')),
      ),
      UserStatus.online,
    );
  });

  test('user_offline marks non-ready member offline', () async {
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

  test('ready_changed keeps offline member visible as ready', () async {
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
      'ready_expires_at': (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600)
          .toString(),
    });
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(
        groupMemberStatusProvider((groupId: 'group-1', userId: 'user-2')),
      ),
      UserStatus.ready,
    );
  });

  test('offline ready member from snapshot still renders as ready', () async {
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
            {
              'user_id': 'user-2',
              'connection': 'offline',
              'ready': true,
              'ready_since': '100',
              'ready_expires_at':
                  (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600)
                      .toString(),
            },
          ],
        },
      ],
    });
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(
        groupMemberStatusProvider((groupId: 'group-1', userId: 'user-2')),
      ),
      UserStatus.ready,
    );
  });

  test(
    'connection_changed away preserves ready as dominant visible status',
    () async {
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
        'type': 'ready_changed',
        'group_id': 'group-1',
        'user_id': 'user-2',
        'ready': true,
        'ready_since': '100',
        'ready_expires_at':
            (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600).toString(),
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
        UserStatus.ready,
      );
    },
  );

  test('deriveMemberStatus prioritizes ready before offline and away', () {
    expect(
      deriveMemberStatus(
        const MemberPresenceState(connection: 'offline', ready: true),
      ),
      UserStatus.ready,
    );
    expect(
      deriveMemberStatus(
        const MemberPresenceState(connection: 'away', ready: true),
      ),
      UserStatus.ready,
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
    expect(
      deriveMemberStatus(
        const MemberPresenceState(connection: 'away', ready: false),
      ),
      UserStatus.away,
    );
  });

  test('toggleReady sends ready_toggle command when connected', () async {
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

    final accepted = container
        .read(presenceNotifierProvider.notifier)
        .toggleReady(groupId: 'group-1', ready: true);

    expect(accepted, isTrue);
    expect(wsClient.sentMessages.single, {
      'type': 'ready_toggle',
      'group_id': 'group-1',
      'ready': true,
    });
  });

  test('toggleReady is rejected when websocket is disconnected', () async {
    final wsClient = _RecordingWebSocketClient()
      ..connectionState = WebSocketConnectionState.disconnected;
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

    final accepted = container
        .read(presenceNotifierProvider.notifier)
        .toggleReady(groupId: 'group-1', ready: true);

    expect(accepted, isFalse);
    expect(wsClient.sentMessages, isEmpty);
    expect(container.read(currentUserReadyProvider('group-1')), isFalse);
  });

  test('toggleReady is rejected while websocket is reconnecting', () async {
    final wsClient = _RecordingWebSocketClient()
      ..connectionState = WebSocketConnectionState.connecting;
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

    final accepted = container
        .read(presenceNotifierProvider.notifier)
        .toggleReady(groupId: 'group-1', ready: true);

    expect(accepted, isFalse);
    expect(wsClient.sentMessages, isEmpty);
  });
}
