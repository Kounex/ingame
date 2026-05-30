import 'package:cue/cue.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/presence_provider.dart';
import 'shared/providers/websocket_provider.dart';

class InGameApp extends ConsumerWidget {
  const InGameApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(websocketConnectionProvider);
    ref.watch(presenceNotifierProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'InGame',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (kDebugMode) {
          return CueDebugTools(child: child!);
        }
        return child!;
      },
    );
  }
}
