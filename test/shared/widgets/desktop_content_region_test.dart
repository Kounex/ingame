import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/shared/widgets/desktop_content_region.dart';

void main() {
  testWidgets('DesktopContentRegion caps content width on desktop', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DesktopContentRegion(
            width: DesktopContentWidth.compact,
            child: SizedBox(
              key: Key('desktop-content-child'),
              width: double.infinity,
              height: 48,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('desktop-content-child'))).width,
      560,
    );
  });

  testWidgets('DesktopContentRegion stays fluid on small screens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DesktopContentRegion(
            width: DesktopContentWidth.compact,
            child: SizedBox(
              key: Key('desktop-content-child'),
              width: double.infinity,
              height: 48,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('desktop-content-child'))).width,
      500,
    );
  });
}
