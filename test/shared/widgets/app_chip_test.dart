import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/shared/widgets/app_chip.dart';

void main() {
  testWidgets('surface app chip renders icon and label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppChip.surface(label: 'Private', icon: Icons.lock_outline),
        ),
      ),
    );

    expect(find.text('Private'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('accent app chip renders label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppChip.accent(label: 'Evening', color: Colors.blue),
        ),
      ),
    );

    expect(find.text('Evening'), findsOneWidget);
  });
}
