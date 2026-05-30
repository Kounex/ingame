import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/networking/websocket_client.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/shared/providers/websocket_provider.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  Future<AuthState> build() async => _initialState;

  void setAuthState(AuthState nextState) {
    state = AsyncValue.data(nextState);
  }
}

class _RecordingWebSocketClient extends WebSocketClient {
  _RecordingWebSocketClient()
    : super(
        baseUrl: 'ws://example.test/api/v1/ws',
        getAccessToken: () async => 'token',
      );

  int connectCalls = 0;
  int disconnectCalls = 0;
  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    connectCalls++;
    _connected = true;
  }

  @override
  void disconnect() {
    disconnectCalls++;
    _connected = false;
  }
}

void main() {
  test('connects on auth and disconnects on logout', () async {
    late _FakeAuthNotifier authNotifier;
    final wsClient = _RecordingWebSocketClient();

    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => authNotifier = _FakeAuthNotifier(const AuthState.unauthenticated()),
        ),
        websocketClientProvider.overrideWithValue(wsClient),
      ],
    );
    addTearDown(container.dispose);

    final subscription = container.listen<void>(
      websocketConnectionProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);
    expect(wsClient.connectCalls, 0);

    authNotifier.setAuthState(
      const AuthState.authenticated(
        User(
          id: 'user-1',
          displayName: 'Ready Player',
          timezone: 'UTC',
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(wsClient.connectCalls, 1);
    expect(wsClient.isConnected, isTrue);

    authNotifier.setAuthState(const AuthState.unauthenticated());
    await Future<void>.delayed(Duration.zero);

    expect(wsClient.disconnectCalls, 1);
    expect(wsClient.isConnected, isFalse);
  });
}
