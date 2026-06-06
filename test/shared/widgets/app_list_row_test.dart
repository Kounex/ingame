import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/shared/widgets/app_list_row.dart';

void main() {
  testWidgets('app list row renders title subtitle and trailing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppListRow(
            leading: Icon(Icons.person),
            title: Text('Account'),
            subtitle: Text('Connected'),
            trailing: Icon(Icons.chevron_right),
          ),
        ),
      ),
    );

    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('app list row forwards taps when interactive', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppListRow(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Settings'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
