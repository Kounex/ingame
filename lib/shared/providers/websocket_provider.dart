import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/networking/websocket_client.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final websocketConnectionProvider = Provider<void>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final wsClient = ref.read(websocketClientProvider);

  authState.whenData((state) {
    state.maybeWhen(
      authenticated: (_) {
        if (!wsClient.isConnected) {
          unawaited(wsClient.connect());
        }
      },
      unauthenticated: () {
        wsClient.disconnect();
      },
      orElse: () {},
    );
  });
});
