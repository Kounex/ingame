import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/l10n/app_localizations.dart';
import 'package:ingame/shared/services/app_haptics.dart';
import 'package:ingame/shared/widgets/weekly_availability_editor.dart';

void main() {
  Future<void> pumpEditor(
    WidgetTester tester, {
    Map<String, dynamic>? initialHours,
    ValueChanged<Map<String, dynamic>>? onChanged,
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
            body: SingleChildScrollView(
              child: WeeklyAvailabilityEditor(
                initialHours: initialHours,
                onChanged: onChanged,
                showTitle: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('emits per-day multi-slot ranges from preset taps', (
    tester,
  ) async {
    Map<String, dynamic>? latestHours;

    await pumpEditor(tester, onChanged: (hours) => latestHours = hours);

    await tester.tap(
      find.byKey(const Key('weekly-availability-chip-monday-morning')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('weekly-availability-chip-monday-evening')),
    );
    await tester.pumpAndSettle();

    expect(latestHours, {
      'monday': [
        {'start': '06:00', 'end': '12:00'},
        {'start': '18:00', 'end': '00:00'},
      ],
    });
  });

  testWidgets('all day preset expands to all standard slot ranges', (
    tester,
  ) async {
    Map<String, dynamic>? latestHours;

    await pumpEditor(tester, onChanged: (hours) => latestHours = hours);

    await tester.scrollUntilVisible(
      find.byKey(const Key('weekly-availability-chip-saturday-all-day')),
      300,
    );
    await tester.tap(
      find.byKey(const Key('weekly-availability-chip-saturday-all-day')),
    );
    await tester.pumpAndSettle();

    expect(latestHours, {
      'saturday': [
        {'start': '06:00', 'end': '12:00'},
        {'start': '12:00', 'end': '18:00'},
        {'start': '18:00', 'end': '00:00'},
        {'start': '00:00', 'end': '06:00'},
      ],
    });
  });

  testWidgets('full-day initial ranges mark all day as selected', (
    tester,
  ) async {
    await pumpEditor(
      tester,
      initialHours: {
        'wednesday': [
          {'start': '06:00', 'end': '12:00'},
          {'start': '12:00', 'end': '18:00'},
          {'start': '18:00', 'end': '00:00'},
          {'start': '00:00', 'end': '06:00'},
        ],
      },
    );

    final chip = tester.widget<FilterChip>(
      find.byKey(const Key('weekly-availability-chip-wednesday-all-day')),
    );

    expect(chip.selected, isTrue);
  });

  testWidgets('selected preset chips hide the default checkmark', (tester) async {
    await pumpEditor(
      tester,
      initialHours: {
        'monday': [
          {'start': '06:00', 'end': '12:00'},
        ],
      },
    );

    final chip = tester.widget<FilterChip>(
      find.byKey(const Key('weekly-availability-chip-monday-morning')),
    );

    expect(chip.selected, isTrue);
    expect(chip.showCheckmark, isFalse);
  });

  testWidgets('preset taps trigger subtle haptics', (tester) async {
    var hapticCount = 0;

    await pumpEditor(
      tester,
      haptics: AppHaptics(
        isWeb: false,
        platform: TargetPlatform.android,
        selectionCallback: () async => hapticCount++,
      ),
    );

    await tester.tap(
      find.byKey(const Key('weekly-availability-chip-monday-morning')),
    );
    await tester.pumpAndSettle();

    expect(hapticCount, 1);
  });

  testWidgets('legacy custom ranges stay selected and are preserved on edit', (
    tester,
  ) async {
    Map<String, dynamic>? latestHours;

    await pumpEditor(
      tester,
      initialHours: {
        'monday': [
          {'start': '18:00', 'end': '22:00'},
        ],
      },
      onChanged: (hours) => latestHours = hours,
    );

    final legacyChip = tester.widget<FilterChip>(
      find.byKey(const Key('weekly-availability-chip-monday-18:00-22:00')),
    );
    expect(legacyChip.selected, isTrue);

    await tester.tap(
      find.byKey(const Key('weekly-availability-chip-monday-morning')),
    );
    await tester.pumpAndSettle();

    expect(latestHours, {
      'monday': [
        {'start': '06:00', 'end': '12:00'},
        {'start': '18:00', 'end': '22:00'},
      ],
    });
  });
}
