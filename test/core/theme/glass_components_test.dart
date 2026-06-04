import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/theme/glass_components.dart';

void main() {
  testWidgets('GlassInput constrains the suffix icon slot', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassInput(suffixIcon: SizedBox(width: 18, height: 18)),
        ),
      ),
    );

    final inputDecorator = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );

    expect(inputDecorator.decoration.isDense, isTrue);
    expect(
      inputDecorator.decoration.suffixIconConstraints,
      const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  });
}
