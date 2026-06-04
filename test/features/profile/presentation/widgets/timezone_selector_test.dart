import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/features/profile/presentation/widgets/timezone_selector.dart';
import 'package:ingame/l10n/app_localizations.dart';

void main() {
  Future<void> pumpTimezoneSelector(
    WidgetTester tester, {
    required String selectedTimezone,
    required ValueChanged<String> onChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: TimezoneSelector(
            selectedTimezone: selectedTimezone,
            onChanged: onChanged,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('timezone selector uses styled popup menu and updates value', (
    tester,
  ) async {
    String? selected;

    await pumpTimezoneSelector(
      tester,
      selectedTimezone: 'Europe/London',
      onChanged: (value) => selected = value,
    );

    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsNothing);

    await tester.tap(find.byKey(const ValueKey('timezone-selector-trigger')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('timezone-option-Europe/Berlin')));
    await tester.pumpAndSettle();

    expect(selected, 'Europe/Berlin');
  });
}
