import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/networking/websocket_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeWebSocketChannel implements WebSocketChannel {
  _FakeWebSocketChannel()
    : _controller = StreamController<dynamic>.broadcast(),
      _sink = _FakeWebSocketSink();

  final StreamController<dynamic> _controller;
  late final _FakeWebSocketSink _sink;

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

  Future<void> closeFromServer() => _controller.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWebSocketSink implements WebSocketSink {
  void Function()? onClose;
  void Function(String message)? onAdd;

  @override
  Future<dynamic> get done async => null;

  @override
  void add(message) {
    onAdd?.call(message as String);
  }

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
  test('reconnect reads a fresh access token', () async {
    final requestedUris = <Uri>[];
    final channels = <_FakeWebSocketChannel>[];
    final tokens = ['token-1', 'token-2'];
    var tokenReads = 0;

    final client = WebSocketClient(
      baseUrl: 'ws://example.test/api/v1/ws',
      getAccessToken: () async => tokens[tokenReads++],
      createChannel: (uri) {
        requestedUris.add(uri);
        final channel = _FakeWebSocketChannel();
        channels.add(channel);
        return channel;
      },
    );

    await client.connect();
    expect(requestedUris.single.queryParameters['token'], 'token-1');

    await channels.single.closeFromServer();
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    expect(requestedUris.length, 2);
    expect(requestedUris.last.queryParameters['token'], 'token-2');

    client.dispose();
  });

  test('sendReadyToggle encodes ready_toggle command', () async {
    final sinkMessages = <String>[];
    final client = WebSocketClient(
      baseUrl: 'ws://example.test/api/v1/ws',
      getAccessToken: () async => 'token',
      createChannel: (uri) {
        final channel = _FakeWebSocketChannel();
        channel._sink.onAdd = sinkMessages.add;
        return channel;
      },
    );

    await client.connect();
    client.sendReadyToggle(groupId: 'group-1', ready: true);

    expect(sinkMessages.single, '{"type":"ready_toggle","group_id":"group-1","ready":true}');
    client.dispose();
  });
}
