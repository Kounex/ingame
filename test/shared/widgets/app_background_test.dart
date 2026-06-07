import 'dart:ui';

import 'package:cue/cue.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/shared/widgets/app_background.dart';

void main() {
  test(
    'production ambient intensity uses shader-native and fallback/web baselines',
    () {
      expect(
        productionAmbientIntensityForRenderMode(
          isWeb: false,
          platform: TargetPlatform.iOS,
          renderMode: AmbientRenderMode.shader,
        ),
        0.0,
      );
      expect(
        productionAmbientIntensityForRenderMode(
          isWeb: false,
          platform: TargetPlatform.iOS,
          renderMode: AmbientRenderMode.fallback,
        ),
        0.8,
      );
      expect(
        productionAmbientIntensityForRenderMode(
          isWeb: true,
          platform: TargetPlatform.iOS,
          renderMode: AmbientRenderMode.shader,
        ),
        0.8,
      );
    },
  );

  testWidgets(
    'AmbientMotionLayer exposes the renderer-aware baseline intensity',
    (tester) async {
      double? capturedIntensity;

      await tester.pumpWidget(
        MaterialApp(
          home: AmbientMotionLayer(
            child: Builder(
              builder: (context) {
                capturedIntensity = AmbientMotionScope.maybeOf(
                  context,
                )?.intensity;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );

      expect(capturedIntensity, 0.0);
    },
  );

  testWidgets('AmbientMotionController updates the shared intensity value', (
    tester,
  ) async {
    final controller = AmbientMotionController();

    expect(controller.intensity, 0.0);

    controller.setIntensity(0.78);

    expect(controller.intensity, 0.78);
  });

  test(
    'AmbientMotionController tracks renderer baseline until user overrides',
    () {
      final controller = AmbientMotionController(intensity: 0.0);

      controller.syncProductionIntensityForRenderMode(
        isWeb: false,
        platform: TargetPlatform.iOS,
        renderMode: AmbientRenderMode.fallback,
      );
      expect(controller.intensity, 0.8);

      controller.setIntensity(0.4);
      controller.syncProductionIntensityForRenderMode(
        isWeb: false,
        platform: TargetPlatform.iOS,
        renderMode: AmbientRenderMode.shader,
      );
      expect(controller.intensity, 0.4);
    },
  );

  test('AmbientMotionController toggles diagnostic shader controls', () {
    final controller = AmbientMotionController();

    expect(controller.diagnosticShaderModeEnabled, isFalse);
    expect(controller.scrimBypassedForDebug, isFalse);

    controller.setDiagnosticShaderModeEnabled(true);
    controller.setScrimBypassedForDebug(true);

    expect(controller.diagnosticShaderModeEnabled, isTrue);
    expect(controller.scrimBypassedForDebug, isTrue);
  });

  test('shader color channels stay normalized for fragment uniforms', () {
    final channels = normalizedShaderColorChannels(const Color(0xFF804020));

    expect(channels[0], closeTo(128 / 255, 0.0001));
    expect(channels[1], closeTo(64 / 255, 0.0001));
    expect(channels[2], closeTo(32 / 255, 0.0001));
  });

  test('ambient shader loop progress wraps cleanly at the cycle boundary', () {
    expect(normalizedAmbientLoopProgress(0.0), 0.0);
    expect(normalizedAmbientLoopProgress(0.25), 0.25);
    expect(normalizedAmbientLoopProgress(1.0), 0.0);
    expect(normalizedAmbientLoopProgress(2.25), 0.25);
  });

  test(
    'shader visibility boost leaves web neutral and boosts mobile native',
    () {
      expect(
        shaderVisibilityBoostForPlatform(
          isWeb: true,
          platform: TargetPlatform.iOS,
        ),
        1.0,
      );
      expect(
        shaderVisibilityBoostForPlatform(
          isWeb: false,
          platform: TargetPlatform.iOS,
        ),
        greaterThan(1.0),
      );
      expect(
        shaderVisibilityBoostForPlatform(
          isWeb: false,
          platform: TargetPlatform.android,
        ),
        greaterThan(1.0),
      );
      expect(
        shaderVisibilityBoostForPlatform(
          isWeb: false,
          platform: TargetPlatform.macOS,
        ),
        1.0,
      );
    },
  );

  test('mobile shader tuning tightens blobs without affecting web', () {
    final web = shaderTuningForPlatform(
      isWeb: true,
      platform: TargetPlatform.iOS,
    );
    final mobile = shaderTuningForPlatform(
      isWeb: false,
      platform: TargetPlatform.iOS,
    );

    expect(web.blobRadiusScale, 1.0);
    expect(web.blobSoftnessScale, 1.0);
    expect(web.motionScale, 1.0);
    expect(web.accentStrength, 1.0);
    expect(web.glowStrength, 1.0);
    expect(web.distortionAmount, 0.0);
    expect(mobile.blobRadiusScale, lessThan(1.0));
    expect(mobile.blobSoftnessScale, lessThan(1.0));
    expect(mobile.motionScale, greaterThan(1.0));
    expect(mobile.accentStrength, greaterThan(1.0));
    expect(mobile.glowStrength, greaterThan(1.0));
    expect(mobile.distortionAmount, greaterThan(0.0));
  });

  test('diagnostic shader tuning is much more explicit than normal mobile', () {
    final normal = shaderTuningForPlatform(
      isWeb: false,
      platform: TargetPlatform.iOS,
    );
    final diagnostic = shaderTuningForPlatform(
      isWeb: false,
      platform: TargetPlatform.iOS,
      diagnosticModeEnabled: true,
    );

    expect(diagnostic.visibilityBoost, greaterThan(normal.visibilityBoost));
    expect(diagnostic.blobRadiusScale, lessThan(normal.blobRadiusScale));
    expect(diagnostic.blobSoftnessScale, lessThan(normal.blobSoftnessScale));
    expect(diagnostic.motionScale, greaterThan(normal.motionScale));
    expect(diagnostic.accentStrength, greaterThan(normal.accentStrength));
    expect(diagnostic.glowStrength, greaterThan(normal.glowStrength));
    expect(
      diagnostic.distortionAmount,
      greaterThanOrEqualTo(normal.distortionAmount),
    );
  });

  testWidgets(
    'AmbientMotionDebugLayer builds without layout or overlay errors',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AmbientMotionDebugLayer(
            child: Scaffold(body: SizedBox.expand()),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Debug'), findsOneWidget);
    },
  );

  testWidgets(
    'AmbientMotionDebugLayer starts collapsed and expands on demand',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AmbientMotionDebugLayer(
            child: Scaffold(body: SizedBox.expand()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Debug'), findsOneWidget);
      expect(find.text('Motion'), findsNothing);
      expect(find.text('Shader'), findsNothing);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('Motion'), findsOneWidget);
      expect(find.text('Shader'), findsOneWidget);
    },
  );

  testWidgets(
    'AmbientMotionDebugLayer stays stable across view focus changes',
    (tester) async {
      FlutterView? view;
      final errors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() {
        FlutterError.onError = previousOnError;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AmbientMotionDebugLayer(
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  view = View.of(context);
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      ServicesBinding.instance.platformDispatcher.onViewFocusChange?.call(
        ViewFocusEvent(
          viewId: view!.viewId,
          state: ViewFocusState.unfocused,
          direction: ViewFocusDirection.forward,
        ),
      );
      await tester.pump();

      ServicesBinding.instance.platformDispatcher.onViewFocusChange?.call(
        ViewFocusEvent(
          viewId: view!.viewId,
          state: ViewFocusState.focused,
          direction: ViewFocusDirection.forward,
        ),
      );
      await tester.pump();

      expect(errors, isEmpty);
    },
  );

  testWidgets('CueDebugTools stays stable across view focus changes', (
    tester,
  ) async {
    FlutterView? view;
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() {
      FlutterError.onError = previousOnError;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: CueDebugTools(
          child: Scaffold(
            body: Builder(
              builder: (context) {
                view = View.of(context);
                return const Cue.onMount(
                  child: SizedBox.expand(),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    ServicesBinding.instance.platformDispatcher.onViewFocusChange?.call(
      ViewFocusEvent(
        viewId: view!.viewId,
        state: ViewFocusState.unfocused,
        direction: ViewFocusDirection.forward,
      ),
    );
    await tester.pump();

    ServicesBinding.instance.platformDispatcher.onViewFocusChange?.call(
      ViewFocusEvent(
        viewId: view!.viewId,
        state: ViewFocusState.focused,
        direction: ViewFocusDirection.forward,
      ),
    );
    await tester.pump();

    expect(errors, isEmpty);
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

  testWidgets('SharedAnimatedBackground reports fallback mode when forced', (
    tester,
  ) async {
    AmbientRenderMode? renderMode;

    await tester.pumpWidget(
      MaterialApp(
        home: AmbientMotionLayer(
          child: Builder(
            builder: (context) {
              renderMode = AmbientMotionScope.maybeOf(context)?.renderMode;
              return const SizedBox(
                width: 800,
                height: 600,
                child: SharedAnimatedBackground(forceFallback: true),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(renderMode, AmbientRenderMode.fallback);
  });

  testWidgets(
    'SharedAnimatedBackground visibly moves the primary orb over time',
    (tester) async {
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

      final primaryOrbFinder = find.byKey(
        const ValueKey('ambient-orb-primary'),
      );
      expect(primaryOrbFinder, findsOneWidget);

      final initialTopLeft = tester.getTopLeft(primaryOrbFinder);
      await tester.pump(const Duration(seconds: 2));
      final movedTopLeft = tester.getTopLeft(primaryOrbFinder);

      expect((movedTopLeft - initialTopLeft).distance, greaterThan(30));
    },
  );

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

    expect((afterWrapTopLeft - beforeWrapTopLeft).distance, lessThan(12));
  });

  testWidgets(
    'AppBackgroundSurface keeps content visible over a translucent scrim',
    (tester) async {
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
    },
  );

  testWidgets('AppBackgroundSurface can bypass the scrim for debug diagnosis', (
    tester,
  ) async {
    final controller = AmbientMotionController()
      ..setScrimBypassedForDebug(true);

    await tester.pumpWidget(
      MaterialApp(
        home: AmbientMotionScope(
          controller: controller,
          child: const AppBackgroundSurface(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(child: Text('Ambient')),
            ),
          ),
        ),
      ),
    );

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

    expect(colors.first.a, closeTo(0, 0.001));
    expect(colors.last.a, closeTo(0, 0.001));
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
