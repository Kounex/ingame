import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/shared/services/app_haptics.dart';
import 'package:ingame/shared/widgets/app_dropdown_selector.dart';

void main() {
  testWidgets('surface dropdown opens and shows selected row checkmark', (
    tester,
  ) async {
    String selected = 'de';

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AppDropdownSelector<String>.surface(
              key: const ValueKey('dropdown-surface'),
              value: selected,
              options: const [
                AppDropdownOption(value: 'en', label: 'English'),
                AppDropdownOption(value: 'de', label: 'Deutsch'),
              ],
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dropdown-surface')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    expect(selected, 'en');
  });

  testWidgets('field dropdown triggers haptics on open and selection', (
    tester,
  ) async {
    var haptics = 0;
    String selected = 'proposed';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appHapticsProvider.overrideWithValue(
            AppHaptics(
              isWeb: false,
              platform: TargetPlatform.android,
              selectionCallback: () async => haptics++,
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AppDropdownSelector<String>.field(
              key: const ValueKey('dropdown-field'),
              value: selected,
              labelText: 'Status',
              options: const [
                AppDropdownOption(value: 'proposed', label: 'Proposed'),
                AppDropdownOption(value: 'confirmed', label: 'Confirmed'),
              ],
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('dropdown-field')));
    await tester.pumpAndSettle();

    expect(haptics, 1);

    await tester.tap(find.text('Confirmed').last);
    await tester.pumpAndSettle();

    expect(haptics, 2);
    expect(selected, 'confirmed');
  });
}
