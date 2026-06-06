import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/shared/widgets/app_switch_row.dart';

void main() {
  testWidgets('app switch row forwards value changes', (tester) async {
    var lastValue = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSwitchRow(
            icon: Icons.public,
            title: 'Discoverable',
            subtitle: 'Show the group in directory listings',
            value: false,
            onChanged: (value) => lastValue = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(lastValue, isTrue);
  });

  testWidgets('app switch row disables the switch when onChanged is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppSwitchRow(
            icon: Icons.public,
            title: 'Discoverable',
            subtitle: 'Show the group in directory listings',
            value: false,
          ),
        ),
      ),
    );

    final switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.onChanged, isNull);
  });
}
