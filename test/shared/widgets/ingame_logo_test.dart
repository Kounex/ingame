import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ingame/l10n/app_localizations.dart';
import 'package:ingame/shared/widgets/ingame_logo.dart';

void main() {
  Future<void> pumpLogo(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(
          body: InGameLogo(size: InGameLogoSize.large, showTagline: true),
        ),
      ),
    );
  }

  testWidgets('logo tagline localizes to English and German', (tester) async {
    await pumpLogo(tester, const Locale('en'));
    expect(find.text('Find your squad. Game together.'), findsOneWidget);

    await pumpLogo(tester, const Locale('de'));
    await tester.pumpAndSettle();
    expect(find.text('Finde deine Crew. Spielt zusammen.'), findsOneWidget);
  });
}
