import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/shared/widgets/app_popup_menu_button.dart';

void main() {
  testWidgets(
    'app popup menu button removes hover, highlight, and splash states from menu items',
    (tester) async {
      Color? hoverColor;
      Color? highlightColor;
      Color? splashColor;
      InteractiveInkFeatureFactory? splashFactory;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            hoverColor: Colors.grey,
            highlightColor: Colors.grey,
            splashColor: Colors.grey,
            splashFactory: InkSparkle.splashFactory,
          ),
          home: Scaffold(
            body: Center(
              child: AppPopupMenuButton<int>(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (_) => [
                  PopupMenuItem<int>(
                    value: 1,
                    child: Builder(
                      builder: (context) {
                        final theme = Theme.of(context);
                        hoverColor = theme.hoverColor;
                        highlightColor = theme.highlightColor;
                        splashColor = theme.splashColor;
                        splashFactory = theme.splashFactory;
                        return const Text('Edit');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(hoverColor, Colors.transparent);
      expect(highlightColor, Colors.transparent);
      expect(splashColor, Colors.transparent);
      expect(splashFactory, same(NoSplash.splashFactory));
    },
  );
}
