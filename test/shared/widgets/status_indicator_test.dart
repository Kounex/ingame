import 'package:cue/cue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/shared/widgets/status_indicator.dart';

void main() {
  testWidgets('ready status with pulse renders a Cue pulse ring', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: StatusIndicator(status: UserStatus.ready)),
        ),
      ),
    );

    expect(find.byWidgetPredicate((widget) => widget is Cue), findsOneWidget);
  });
}
