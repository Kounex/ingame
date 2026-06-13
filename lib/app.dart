import 'package:cue/cue.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import 'core/localization/locale_controller.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'features/notifications/presentation/providers/notification_provider.dart';
import 'shared/providers/presence_lifecycle_binder.dart';
import 'shared/providers/presence_provider.dart';
import 'shared/providers/websocket_provider.dart';
import 'shared/widgets/app_background.dart';

class InGameApp extends ConsumerWidget {
  const InGameApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(websocketConnectionProvider);
    ref.watch(presenceNotifierProvider);
    ref.watch(notificationNotifierProvider);
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeControllerProvider);
    final resolvedLocale = ref.watch(resolvedLocaleProvider);

    intl.Intl.defaultLocale = resolvedLocale.toLanguageTag();

    return PresenceLifecycleBinder(
      child: MaterialApp.router(
        onGenerateTitle: (context) =>
            AppLocalizations.of(context)?.appTitle ?? 'InGame',
        theme: AppTheme.darkTheme,
        routerConfig: router,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          final transparentTheme = Theme.of(context).copyWith(
            scaffoldBackgroundColor: Colors.transparent,
            canvasColor: Colors.transparent,
          );
          Widget appChild = Theme(data: transparentTheme, child: child!);

          if (kDebugMode) {
            appChild = CueDebugTools(child: appChild);
          }

          Widget layeredApp = Stack(
            fit: StackFit.expand,
            children: [
              const SharedAnimatedBackground(),
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: AppBackgroundSurface(child: appChild),
                ),
              ),
            ],
          );

          layeredApp = AmbientMotionLayer(
            showDebugOverlay: kDebugMode,
            child: layeredApp,
          );

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppTheme.darkSystemUiOverlayStyle,
            child: layeredApp,
          );
        },
      ),
    );
  }
}
