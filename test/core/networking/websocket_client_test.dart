import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/networking/websocket_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _AsyncReadyFakeWebSocketChannel implements WebSocketChannel {
  _AsyncReadyFakeWebSocketChannel()
    : _controller = StreamController<dynamic>(sync: true),
      _sink = _FakeWebSocketSink(),
      _readyCompleter = Completer<void>();

  final StreamController<dynamic> _controller;
  final _FakeWebSocketSink _sink;
  final Completer<void> _readyCompleter;

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
  Future<void> get ready => _readyCompleter.future;

  void completeReady({String? bootstrapMessage}) {
    if (bootstrapMessage != null) {
      _controller.add(bootstrapMessage);
    }
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

  test('connectionState is disconnected before connect', () {
    final client = WebSocketClient(
      baseUrl: 'ws://example.test/api/v1/ws',
      getAccessToken: () async => 'token',
      createChannel: (_) => _FakeWebSocketChannel(),
    );

    expect(client.connectionState, WebSocketConnectionState.disconnected);
    client.dispose();
  });

  test('connectionState becomes connected after connect', () async {
    final client = WebSocketClient(
      baseUrl: 'ws://example.test/api/v1/ws',
      getAccessToken: () async => 'token',
      createChannel: (_) => _FakeWebSocketChannel(),
    );

    await client.connect();
    expect(client.connectionState, WebSocketConnectionState.connected);
    client.dispose();
  });

  test('connectionState stays connecting until channel ready completes', () async {
    final channels = <_AsyncReadyFakeWebSocketChannel>[];
    final client = WebSocketClient(
      baseUrl: 'ws://example.test/api/v1/ws',
      getAccessToken: () async => 'token',
      createChannel: (uri) {
        final channel = _AsyncReadyFakeWebSocketChannel();
        channels.add(channel);
        return channel;
      },
    );

    final connectFuture = client.connect();
    await Future<void>.delayed(Duration.zero);
    expect(client.connectionState, WebSocketConnectionState.connecting);

    channels.single.completeReady();
    await connectFuture;
    expect(client.connectionState, WebSocketConnectionState.connected);

    client.dispose();
  });

  test('caches bootstrap snapshot emitted when channel becomes ready', () async {
    final channels = <_AsyncReadyFakeWebSocketChannel>[];
    final client = WebSocketClient(
      baseUrl: 'ws://example.test/api/v1/ws',
      getAccessToken: () async => 'token',
      createChannel: (uri) {
        final channel = _AsyncReadyFakeWebSocketChannel();
        channels.add(channel);
        return channel;
      },
    );

    final connectFuture = client.connect();
    await Future<void>.delayed(Duration.zero);

    channels.single.completeReady(
      bootstrapMessage: jsonEncode({
        'type': 'presence_snapshot',
        'groups': [
          {
            'group_id': 'group-1',
            'members': [
              {'user_id': 'user-1', 'connection': 'online', 'ready': false},
            ],
          },
        ],
      }),
    );
    await connectFuture;

    expect(client.cachedPresenceSnapshot, isNotNull);
    expect(
      client.cachedPresenceSnapshot!['groups'][0]['members'][0]['user_id'],
      'user-1',
    );

    client.dispose();
  });

  test('connectionState becomes connecting while reconnect is pending', () async {
    final channels = <_FakeWebSocketChannel>[];
    final client = WebSocketClient(
      baseUrl: 'ws://example.test/api/v1/ws',
      getAccessToken: () async => 'token',
      createChannel: (uri) {
        final channel = _FakeWebSocketChannel();
        channels.add(channel);
        return channel;
      },
    );

    await client.connect();
    expect(client.connectionState, WebSocketConnectionState.connected);

    await channels.single.closeFromServer();
    expect(client.connectionState, WebSocketConnectionState.connecting);

    client.dispose();
  });

  test('connectionState becomes disconnected after explicit disconnect', () async {
    final client = WebSocketClient(
      baseUrl: 'ws://example.test/api/v1/ws',
      getAccessToken: () async => 'token',
      createChannel: (_) => _FakeWebSocketChannel(),
    );

    await client.connect();
    client.disconnect();
    expect(client.connectionState, WebSocketConnectionState.disconnected);
    client.dispose();
  });

  test('caches presence_snapshot received before any event listener attaches',
      () async {
    final channels = <_FakeWebSocketChannel>[];
    final client = WebSocketClient(
      baseUrl: 'ws://example.test/api/v1/ws',
      getAccessToken: () async => 'token',
      createChannel: (uri) {
        final channel = _FakeWebSocketChannel();
        channels.add(channel);
        return channel;
      },
    );

    await client.connect();
    channels.single._controller.add(
      jsonEncode({
        'type': 'presence_snapshot',
        'groups': [
          {
            'group_id': 'group-1',
            'members': [
              {'user_id': 'user-1', 'connection': 'online', 'ready': false},
            ],
          },
        ],
      }),
    );
    await Future<void>.delayed(Duration.zero);

    expect(client.cachedPresenceSnapshot, isNotNull);
    expect(client.cachedPresenceSnapshot!['type'], 'presence_snapshot');

    client.dispose();
  });

  test('clears cached presence_snapshot on disconnect', () async {
    final channels = <_FakeWebSocketChannel>[];
    final client = WebSocketClient(
      baseUrl: 'ws://example.test/api/v1/ws',
      getAccessToken: () async => 'token',
      createChannel: (uri) {
        final channel = _FakeWebSocketChannel();
        channels.add(channel);
        return channel;
      },
    );

    await client.connect();
    channels.single._controller.add(
      jsonEncode({
        'type': 'presence_snapshot',
        'groups': [],
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(client.cachedPresenceSnapshot, isNotNull);

    client.disconnect();
    expect(client.cachedPresenceSnapshot, isNull);

    client.dispose();
  });

  test('connectionState stream emits transitions', () async {
    final client = WebSocketClient(
      baseUrl: 'ws://example.test/api/v1/ws',
      getAccessToken: () async => 'token',
      createChannel: (_) => _FakeWebSocketChannel(),
    );
    final states = <WebSocketConnectionState>[];
    final subscription = client.connectionStateStream.listen(states.add);

    await client.connect();
    client.disconnect();
    await Future<void>.delayed(Duration.zero);

    expect(states, [
      WebSocketConnectionState.connecting,
      WebSocketConnectionState.connected,
      WebSocketConnectionState.disconnected,
    ]);

    await subscription.cancel();
    client.dispose();
  });
}
