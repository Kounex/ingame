import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../auth/auth_session.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
}

class WebSocketClient {
  WebSocketClient({
    required this.baseUrl,
    required this.getAccessToken,
    WebSocketChannel Function(Uri uri)? createChannel,
  }) : createChannel = createChannel ?? WebSocketChannel.connect;

  final String baseUrl;
  final Future<String?> Function() getAccessToken;
  final WebSocketChannel Function(Uri uri) createChannel;
  WebSocketChannel? _channel;
  final _eventController = StreamController<dynamic>.broadcast();
  final _connectionStateController =
      StreamController<WebSocketConnectionState>.broadcast();
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelay = 30;
  bool _disposed = false;
  bool _shouldReconnect = false;
  Future<void>? _connectFuture;
  WebSocketConnectionState _connectionState =
      WebSocketConnectionState.disconnected;
  Map<String, dynamic>? _cachedPresenceSnapshot;

  Stream<dynamic> get events => _eventController.stream;
  Stream<WebSocketConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  WebSocketConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == WebSocketConnectionState.connected;

  /// Last `presence_snapshot` received on the current connection, if any.
  ///
  /// Broadcast event streams do not replay, so this cache lets late subscribers
  /// hydrate after the server bootstrap event arrives on connect.
  Map<String, dynamic>? get cachedPresenceSnapshot {
    final snapshot = _cachedPresenceSnapshot;
    if (snapshot == null) return null;
    return Map<String, dynamic>.from(snapshot);
  }

  void _setConnectionState(WebSocketConnectionState state) {
    if (_connectionState == state) return;
    _connectionState = state;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }

  Future<void> connect() {
    _connectFuture ??= _connectInternal().whenComplete(() {
      _connectFuture = null;
    });
    return _connectFuture!;
  }

  Future<void> _connectInternal() async {
    if (_disposed) return;
    _setConnectionState(WebSocketConnectionState.connecting);
    final token = await getAccessToken();
    if (token == null) {
      disconnect();
      return;
    }

    _shouldReconnect = true;
    _closeChannel();
    _setConnectionState(WebSocketConnectionState.connecting);

    try {
      final uri = Uri.parse('$baseUrl?token=$token');
      _channel = createChannel(uri);
      _reconnectAttempts = 0;

      _channel!.stream.listen(
        (data) {
          final decoded = data is String ? jsonDecode(data) : data;
          _cachePresenceSnapshotIfNeeded(decoded);
          _eventController.add(decoded);
        },
        onError: (error) {
          _eventController.addError(error);
          _channel = null;
          if (_shouldReconnect) {
            _setConnectionState(WebSocketConnectionState.connecting);
            _scheduleReconnect();
          }
        },
        onDone: () {
          _channel = null;
          if (_shouldReconnect) {
            _setConnectionState(WebSocketConnectionState.connecting);
            _scheduleReconnect();
          }
        },
      );

      await _channel!.ready;
      if (_disposed || !_shouldReconnect || _channel == null) return;
      _setConnectionState(WebSocketConnectionState.connected);
    } catch (e) {
      _channel = null;
      _setConnectionState(WebSocketConnectionState.connecting);
      _scheduleReconnect();
    }
  }

  void _cachePresenceSnapshotIfNeeded(dynamic decoded) {
    if (decoded is Map && decoded['type'] == 'presence_snapshot') {
      _cachedPresenceSnapshot = Map<String, dynamic>.from(decoded);
    }
  }

  void send(Map<String, dynamic> message) {
    final channel = _channel;
    if (channel == null) return;
    channel.sink.add(jsonEncode(message));
  }

  void sendPresenceLifecycle(String state) {
    send({'type': 'presence_lifecycle', 'state': state});
  }

  void sendReadyToggle({required String groupId, required bool ready}) {
    send({'type': 'ready_toggle', 'group_id': groupId, 'ready': ready});
  }

  void _scheduleReconnect() {
    if (_disposed || !_shouldReconnect) return;
    _reconnectTimer?.cancel();
    final delay = _calculateBackoff();
    _reconnectTimer = Timer(Duration(seconds: delay), connect);
  }

  int _calculateBackoff() {
    final delay = (1 << _reconnectAttempts).clamp(1, _maxReconnectDelay);
    _reconnectAttempts++;
    return delay;
  }

  void _closeChannel() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _cachedPresenceSnapshot = null;
  }

  void disconnect() {
    _shouldReconnect = false;
    _closeChannel();
    _reconnectAttempts = 0;
    _setConnectionState(WebSocketConnectionState.disconnected);
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _eventController.close();
    _connectionStateController.close();
  }
}

final websocketClientProvider = Provider<WebSocketClient>((ref) {
  ref.watch(sessionResetSignalProvider);
  final storage = ref.read(secureStorageProvider);
  final client = WebSocketClient(
    baseUrl: ApiEndpoints.websocketUrl,
    getAccessToken: storage.getAccessToken,
  );
  ref.onDispose(client.dispose);
  return client;
});
