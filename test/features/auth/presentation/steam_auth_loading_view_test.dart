import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ingame/features/auth/presentation/screens/steam_auth_screen.dart';
import 'package:ingame/l10n/app_localizations.dart';

void main() {
  testWidgets('steam auth loading view exposes cancel action', (tester) async {
    var cancelled = false;

    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: SteamAuthLoadingView(
            onCancel: () {
              cancelled = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Connecting to Steam...'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(cancelled, isTrue);
  });

  testWidgets('loading view supports Discord-specific progress copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(
          body: SteamAuthLoadingView(
            onCancel: _noop,
            message: 'Connecting to Discord...',
          ),
        ),
      ),
    );

    expect(find.text('Connecting to Discord...'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}

void _noop() {}
