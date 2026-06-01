import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/networking/websocket_client.dart';
import 'package:ingame/shared/providers/websocket_provider.dart';

class _FakeWebSocketClient extends WebSocketClient {
  _FakeWebSocketClient()
      : _stateController =
            StreamController<WebSocketConnectionState>.broadcast(),
        super(
          baseUrl: 'ws://example.test/api/v1/ws',
          getAccessToken: () async => 'token',
        );

  final StreamController<WebSocketConnectionState> _stateController;
  WebSocketConnectionState _state = WebSocketConnectionState.disconnected;

  @override
  WebSocketConnectionState get connectionState => _state;

  @override
  Stream<WebSocketConnectionState> get connectionStateStream =>
      _stateController.stream;

  void emitState(WebSocketConnectionState state) {
    _state = state;
    _stateController.add(state);
  }

  @override
  void dispose() {
    _stateController.close();
    super.dispose();
  }
}

void main() {
  test('websocketConnectionStateProvider reflects client connection state',
      () async {
    final client = _FakeWebSocketClient();
    final container = ProviderContainer(
      overrides: [
        websocketClientProvider.overrideWithValue(client),
      ],
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
  });
}
