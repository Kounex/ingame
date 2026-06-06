import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/networking/websocket_client.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class PresenceLifecycleBinder extends ConsumerStatefulWidget {
  const PresenceLifecycleBinder({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PresenceLifecycleBinder> createState() =>
      _PresenceLifecycleBinderState();
}

class _PresenceLifecycleBinderState
    extends ConsumerState<PresenceLifecycleBinder>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final authState = ref.read(authNotifierProvider).value;
    final isAuthenticated =
        authState?.maybeWhen(authenticated: (_) => true, orElse: () => false) ??
        false;
    if (!isAuthenticated) return;

    final wsClient = ref.read(websocketClientProvider);
    if (!wsClient.isConnected) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        wsClient.sendPresenceLifecycle('away');
        break;
      case AppLifecycleState.resumed:
        wsClient.sendPresenceLifecycle('active');
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
