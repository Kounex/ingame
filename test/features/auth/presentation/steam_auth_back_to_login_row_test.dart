import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ingame/core/theme/app_theme.dart';
import 'package:ingame/features/auth/presentation/screens/steam_auth_screen.dart';
import 'package:ingame/l10n/app_localizations.dart';

void main() {
  testWidgets('steam auth back-to-login row highlights only login action', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: SteamAuthBackToLoginRow(
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Back to'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);

    final prefix = tester.widget<Text>(find.text('Back to'));
    final action = tester.widget<Text>(find.text('Log in'));

    expect(prefix.style?.color, AppColors.textTertiary);
    expect(action.style?.color, AppColors.primary);

    await tester.tap(find.text('Log in'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
