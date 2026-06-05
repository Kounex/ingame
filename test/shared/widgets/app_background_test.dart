import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/shared/widgets/app_background.dart';

void main() {
  testWidgets('AmbientMotionController updates the shared intensity value', (
    tester,
  ) async {
    final controller = AmbientMotionController();

    expect(controller.intensity, 0.8);

    controller.setIntensity(0.78);

    expect(controller.intensity, 0.78);
  });

  testWidgets('AmbientMotionDebugLayer builds without layout or overlay errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AmbientMotionDebugLayer(
          child: Scaffold(body: SizedBox.expand()),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Ambient motion'), findsOneWidget);
  });

  testWidgets('SharedAnimatedBackground exposes visible fallback orbs', (
    tester,
  ) async {
    final controller = AmbientMotionController(intensity: 0.8);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AmbientMotionScope(
            controller: controller,
            child: const SizedBox(
              width: 800,
              height: 600,
              child: SharedAnimatedBackground(forceFallback: true),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('ambient-orb-primary')), findsOneWidget);
    expect(find.byKey(const ValueKey('ambient-orb-secondary')), findsOneWidget);
    expect(find.byKey(const ValueKey('ambient-orb-tertiary')), findsOneWidget);
  });

  testWidgets('SharedAnimatedBackground visibly moves the primary orb over time', (
    tester,
  ) async {
    final controller = AmbientMotionController(intensity: 0.8);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AmbientMotionScope(
            controller: controller,
            child: const SizedBox(
              width: 800,
              height: 600,
              child: SharedAnimatedBackground(forceFallback: true),
            ),
          ),
        ),
      ),
    );

    final primaryOrbFinder = find.byKey(const ValueKey('ambient-orb-primary'));
    expect(primaryOrbFinder, findsOneWidget);

    final initialTopLeft = tester.getTopLeft(primaryOrbFinder);
    await tester.pump(const Duration(seconds: 2));
    final movedTopLeft = tester.getTopLeft(primaryOrbFinder);

    expect(
      (movedTopLeft - initialTopLeft).distance,
      greaterThan(30),
    );
  });

  testWidgets('SharedAnimatedBackground loops without a visible jump', (
    tester,
  ) async {
    final controller = AmbientMotionController(intensity: 0.8);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AmbientMotionScope(
            controller: controller,
            child: const SizedBox(
              width: 800,
              height: 600,
              child: SharedAnimatedBackground(forceFallback: true),
            ),
          ),
        ),
      ),
    );

    final primaryOrbFinder = find.byKey(const ValueKey('ambient-orb-primary'));
    expect(primaryOrbFinder, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 19900));
    final beforeWrapTopLeft = tester.getTopLeft(primaryOrbFinder);
    await tester.pump(const Duration(milliseconds: 200));
    final afterWrapTopLeft = tester.getTopLeft(primaryOrbFinder);

    expect(
      (afterWrapTopLeft - beforeWrapTopLeft).distance,
      lessThan(12),
    );
  });

  testWidgets('AppBackgroundSurface keeps content visible over a translucent scrim', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppBackgroundSurface(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: Text('Ambient')),
          ),
        ),
      ),
    );

    expect(find.text('Ambient'), findsOneWidget);

    final decoratedBox = tester.widget<DecoratedBox>(
      find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).gradient is LinearGradient,
      ),
    );
    final gradient = decoratedBox.decoration as BoxDecoration;
    final colors = (gradient.gradient! as LinearGradient).colors;

    expect(colors, hasLength(2));
    expect(colors.first.a, lessThan(1));
    expect(colors.last.a, lessThan(1));
  });

  testWidgets('AppBackgroundSurface does not duplicate its scrim when nested', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppBackgroundSurface(
          child: AppBackgroundSurface(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(child: Text('Nested ambient')),
            ),
          ),
        ),
      ),
    );

    final gradientDecoratedBoxes = find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).gradient is LinearGradient,
    );

    expect(find.text('Nested ambient'), findsOneWidget);
    expect(gradientDecoratedBoxes, findsOneWidget);
  });
}
