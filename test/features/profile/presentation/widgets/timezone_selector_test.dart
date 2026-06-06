import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/features/profile/presentation/widgets/timezone_selector.dart';
import 'package:ingame/l10n/app_localizations.dart';
import 'package:ingame/shared/services/app_haptics.dart';

void main() {
  AppHaptics buildRecordingHaptics({required VoidCallback onSelection}) {
    return AppHaptics(
      isWeb: false,
      platform: TargetPlatform.android,
      selectionCallback: () async => onSelection(),
    );
  }

  Future<void> pumpTimezoneSelector(
    WidgetTester tester, {
    required String selectedTimezone,
    required ValueChanged<String> onChanged,
    AppHaptics? haptics,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (haptics != null) appHapticsProvider.overrideWithValue(haptics),
        ],
        child: MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: TimezoneSelector(
              selectedTimezone: selectedTimezone,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollToTimezoneOption(
    WidgetTester tester,
    String timezone,
  ) async {
    final optionFinder = find.byKey(ValueKey('timezone-option-$timezone'));
    await tester.scrollUntilVisible(
      optionFinder,
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(optionFinder);
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

    await tester.tap(find.byKey(const ValueKey('timezone-selector-trigger')));
    await tester.pumpAndSettle();
    await scrollToTimezoneOption(tester, 'Europe/Berlin');

    expect(selected, 'Europe/Berlin');
  });

  testWidgets('timezone selector preserves custom saved timezones', (
    tester,
  ) async {
    await pumpTimezoneSelector(
      tester,
      selectedTimezone: 'UTC',
      onChanged: (_) {},
    );

    expect(find.text('UTC'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('timezone-selector-trigger')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('timezone-option-UTC')), findsOneWidget);
  });

  test('timezone selector uses shared anchored popover widget', () {
    final source = File(
      'lib/features/profile/presentation/widgets/timezone_selector.dart',
    ).readAsStringSync();

    expect(source, contains('AppAnchoredPopoverSelector<String>('));
  });

  testWidgets('timezone selector triggers haptics on open and selection', (
    tester,
  ) async {
    var hapticCount = 0;

    await pumpTimezoneSelector(
      tester,
      selectedTimezone: 'Europe/London',
      onChanged: (_) {},
      haptics: buildRecordingHaptics(onSelection: () => hapticCount++),
    );

    await tester.tap(find.byKey(const ValueKey('timezone-selector-trigger')));
    await tester.pumpAndSettle();

    expect(hapticCount, 1);

    await scrollToTimezoneOption(tester, 'Europe/Berlin');

    expect(hapticCount, 2);
  });
}
