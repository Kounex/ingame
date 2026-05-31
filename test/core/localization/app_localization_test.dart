import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ingame/app.dart';
import 'package:ingame/core/storage/preferences.dart';
import 'package:ingame/features/auth/presentation/screens/login_screen.dart';
import 'package:ingame/l10n/app_localizations.dart';

void main() {
  testWidgets('InGameApp supports English and German locales', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(PreferencesService(prefs)),
        ],
        child: const InGameApp(),
      ),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.supportedLocales, contains(const Locale('en')));
    expect(app.supportedLocales, contains(const Locale('de')));
    expect(app.localizationsDelegates, isNotNull);
  });

  testWidgets('login screen renders German localized copy', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('de'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('E-Mail'), findsOneWidget);
    expect(find.text('Passwort'), findsOneWidget);
    expect(find.text('Anmelden'), findsOneWidget);
    expect(find.text('Noch kein Konto?'), findsOneWidget);
    expect(find.text('Registrieren'), findsOneWidget);
    expect(find.text('oder'), findsOneWidget);
    expect(find.text('Mit Steam fortfahren'), findsOneWidget);
  });
}
