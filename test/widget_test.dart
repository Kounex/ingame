import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ingame/app.dart';
import 'package:ingame/core/storage/preferences.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
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
  });
}
