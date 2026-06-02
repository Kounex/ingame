import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/networking/websocket_client.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/shared/providers/websocket_provider.dart';

class _FakeWebSocketClient extends WebSocketClient {
  _FakeWebSocketClient()
    : _stateController = StreamController<WebSocketConnectionState>.broadcast(),
      super(
        baseUrl: 'ws://example.test/api/v1/ws',
        getAccessToken: () async => 'token',
      );

  final StreamController<WebSocketConnectionState> _stateController;
  WebSocketConnectionState _state = WebSocketConnectionState.disconnected;
  int connectCalls = 0;
  int disconnectCalls = 0;

  @override
  WebSocketConnectionState get connectionState => _state;

  @override
  bool get isConnected => _state == WebSocketConnectionState.connected;

  @override
  Stream<WebSocketConnectionState> get connectionStateStream =>
      _stateController.stream;

  void emitState(WebSocketConnectionState state) {
    _state = state;
    _stateController.add(state);
  }

  @override
  Future<void> connect() async {
    connectCalls++;
    emitState(WebSocketConnectionState.connected);
  }

  @override
  void disconnect() {
    disconnectCalls++;
    emitState(WebSocketConnectionState.disconnected);
  }

  @override
  void dispose() {
    _stateController.close();
    super.dispose();
  }
}

class _ControllableAuthNotifier extends AuthNotifier {
  _ControllableAuthNotifier(this._initialState);

  AuthState _initialState;

  @override
  Future<AuthState> build() async => _initialState;

  void setAuthState(AuthState next) {
    _initialState = next;
    state = AsyncValue.data(next);
  }
}

void main() {
  test(
    'websocketConnectionStateProvider reflects client connection state',
    () async {
      final client = _FakeWebSocketClient();
      final container = ProviderContainer(
        overrides: [websocketClientProvider.overrideWithValue(client)],
      );
      addTearDown(container.dispose);

      expect(
        container.read(websocketConnectionStateProvider),
        WebSocketConnectionState.disconnected,
      );

      client.emitState(WebSocketConnectionState.connecting);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(websocketConnectionStateProvider),
        WebSocketConnectionState.connecting,
      );

      client.emitState(WebSocketConnectionState.connected);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(websocketConnectionStateProvider),
        WebSocketConnectionState.connected,
      );
    },
  );

  test(
    'websocketConnectionProvider connects on auth and disconnects on logout',
    () async {
      final client = _FakeWebSocketClient();
      late _ControllableAuthNotifier authNotifier;
      final container = ProviderContainer(
        overrides: [
          websocketClientProvider.overrideWithValue(client),
          authNotifierProvider.overrideWith(
            () => authNotifier = _ControllableAuthNotifier(
              const AuthState.unauthenticated(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);
      final sub = container.listen(
        websocketConnectionProvider,
        (_, next) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);
      expect(client.connectCalls, 0);
      expect(client.disconnectCalls, 1);

      authNotifier.setAuthState(
        const AuthState.authenticated(
          User(id: 'user-1', displayName: 'Ready Player', timezone: 'UTC'),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(client.connectCalls, 1);

      authNotifier.setAuthState(const AuthState.unauthenticated());
      await Future<void>.delayed(Duration.zero);
      expect(client.disconnectCalls, 2);
    },
  );
}
