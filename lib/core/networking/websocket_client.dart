import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

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
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelay = 30;
  bool _disposed = false;
  bool _shouldReconnect = false;
  Future<void>? _connectFuture;

  Stream<dynamic> get events => _eventController.stream;
  bool get isConnected => _channel != null;

  Future<void> connect() {
    _connectFuture ??= _connectInternal().whenComplete(() {
      _connectFuture = null;
    });
    return _connectFuture!;
  }

  Future<void> _connectInternal() async {
    if (_disposed) return;
    final token = await getAccessToken();
    if (token == null) {
      disconnect();
      return;
    }

    _shouldReconnect = true;
    disconnect();
    _shouldReconnect = true;

    try {
      final uri = Uri.parse('$baseUrl?token=$token');
      _channel = createChannel(uri);
      _reconnectAttempts = 0;

      _channel!.stream.listen(
        (data) {
          final decoded = data is String ? jsonDecode(data) : data;
          _eventController.add(decoded);
        },
        onError: (error) {
          _eventController.addError(error);
          _scheduleReconnect();
        },
        onDone: () {
          _channel = null;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _channel = null;
      _scheduleReconnect();
    }
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

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _reconnectAttempts = 0;
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _eventController.close();
  }
}

final websocketClientProvider = Provider<WebSocketClient>((ref) {
  final storage = ref.read(secureStorageProvider);
  final client = WebSocketClient(
    baseUrl: ApiEndpoints.websocketUrl,
    getAccessToken: storage.getAccessToken,
  );
  ref.onDispose(client.dispose);
  return client;
});
