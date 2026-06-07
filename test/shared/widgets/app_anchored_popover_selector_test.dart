import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/shared/services/app_haptics.dart';
import 'package:ingame/shared/widgets/app_anchored_popover_selector.dart';

void main() {
  AppHaptics buildRecordingHaptics({required VoidCallback onSelection}) {
    return AppHaptics(
      isWeb: false,
      platform: TargetPlatform.android,
      selectionCallback: () async => onSelection(),
    );
  }

  Future<void> pumpPopoverHarness(
    WidgetTester tester, {
    required Widget child,
    AppHaptics? haptics,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (haptics != null) appHapticsProvider.overrideWithValue(haptics),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<AppAnchoredPopoverOption<String>> buildOptions(int count) {
    return List.generate(
      count,
      (index) => AppAnchoredPopoverOption(
        value: 'item-$index',
        label: 'Item $index',
        key: ValueKey('popover-option-$index'),
      ),
    );
  }

  testWidgets('anchored popover caps long lists and shows a scrollbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpPopoverHarness(
      tester,
      child: Center(
        child: SizedBox(
          width: 240,
          child: AppAnchoredPopoverSelector<String>(
            panelKey: const ValueKey('popover-panel'),
            value: 'item-0',
            options: buildOptions(20),
            onSelected: (_) {},
            triggerBuilder: (context, openPopover, isOpen) {
              return GestureDetector(
                key: const ValueKey('popover-trigger'),
                onTap: openPopover,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(height: 44, child: Text('Open')),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('popover-trigger')));
    await tester.pumpAndSettle();

    expect(find.byType(Scrollbar), findsOneWidget);

    final panelRect = tester.getRect(
      find.byKey(const ValueKey('popover-panel')),
    );
    expect(panelRect.height, lessThanOrEqualTo(400));
  });

  testWidgets('anchored popover prefers opening upward near bottom edge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpPopoverHarness(
      tester,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: 240,
            child: AppAnchoredPopoverSelector<String>(
              panelKey: const ValueKey('popover-panel'),
              value: 'item-0',
              options: buildOptions(20),
              onSelected: (_) {},
              triggerBuilder: (context, openPopover, isOpen) {
                return GestureDetector(
                  key: const ValueKey('popover-trigger'),
                  onTap: openPopover,
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(height: 44, child: Text('Open')),
                );
              },
            ),
          ),
        ),
      ),
    );

    final triggerRect = tester.getRect(
      find.byKey(const ValueKey('popover-trigger')),
    );

    await tester.tap(find.byKey(const ValueKey('popover-trigger')));
    await tester.pumpAndSettle();

    final panelRect = tester.getRect(
      find.byKey(const ValueKey('popover-panel')),
    );
    expect(panelRect.bottom, lessThanOrEqualTo(triggerRect.top + 8));
  });

  testWidgets('anchored popover triggers haptics and selection callback', (
    tester,
  ) async {
    var hapticCount = 0;
    String? selected;

    await pumpPopoverHarness(
      tester,
      haptics: buildRecordingHaptics(onSelection: () => hapticCount++),
      child: Center(
        child: SizedBox(
          width: 240,
          child: AppAnchoredPopoverSelector<String>(
            panelKey: const ValueKey('popover-panel'),
            value: 'item-0',
            options: buildOptions(4),
            onSelected: (value) => selected = value,
            triggerBuilder: (context, openPopover, isOpen) {
              return GestureDetector(
                key: const ValueKey('popover-trigger'),
                onTap: openPopover,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(height: 44, child: Text('Open')),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('popover-trigger')));
    await tester.pumpAndSettle();

    expect(hapticCount, 1);

    await tester.tap(find.byKey(const ValueKey('popover-option-2')));
    await tester.pumpAndSettle();

    expect(selected, 'item-2');
    expect(hapticCount, 2);
  });

  testWidgets('anchored popover omits scrollbar for short lists', (
    tester,
  ) async {
    await pumpPopoverHarness(
      tester,
      child: Center(
        child: SizedBox(
          width: 240,
          child: AppAnchoredPopoverSelector<String>(
            panelKey: const ValueKey('popover-panel'),
            value: 'item-0',
            options: buildOptions(2),
            onSelected: (_) {},
            triggerBuilder: (context, openPopover, isOpen) {
              return GestureDetector(
                key: const ValueKey('popover-trigger'),
                onTap: openPopover,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(height: 44, child: Text('Open')),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('popover-trigger')));
    await tester.pumpAndSettle();

    expect(find.byType(Scrollbar), findsNothing);
  });

  testWidgets('shared popover menu item highlights the selected option', (
    tester,
  ) async {
    await pumpPopoverHarness(
      tester,
      child: const Center(
        child: AppAnchoredPopoverMenuItem(label: 'Deutsch', selected: true),
      ),
    );

    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('shared popover menu item uses app-standard motion timing', (
    tester,
  ) async {
    await pumpPopoverHarness(
      tester,
      child: const Center(
        child: AppAnchoredPopoverMenuItem(label: 'English', selected: false),
      ),
    );

    final animatedContainer = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );

    expect(animatedContainer.duration, const Duration(milliseconds: 220));
    expect(animatedContainer.curve, Curves.easeOutCubic);
  });
}
