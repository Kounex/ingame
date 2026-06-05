import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/routing/page_transitions.dart';
import 'package:go_router/go_router.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('adaptiveRoutePage returns CupertinoPage on iOS', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final page = adaptiveRoutePage(
      key: const ValueKey('ios'),
      child: const SizedBox.shrink(),
    );

    expect(page, isA<CupertinoPage<void>>());
  });

  test('adaptiveRoutePage returns MaterialPage on Android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final page = adaptiveRoutePage(
      key: const ValueKey('android'),
      child: const SizedBox.shrink(),
    );

    expect(page, isA<MaterialPage<void>>());
  });

  test('fadeSlideTransition still returns CustomTransitionPage', () {
    final page = fadeSlideTransition(
      key: const ValueKey('web-style'),
      child: const SizedBox.shrink(),
    );

    expect(page, isA<CustomTransitionPage<void>>());
  });

  testWidgets(
    'fade slide transition delays incoming route opacity at the start',
    (tester) async {
      const childKey = ValueKey('adaptive-incoming-child');
      final page = fadeSlideTransition(
        key: const ValueKey('adaptive-web'),
        child: const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(key: childKey, width: 120, height: 120),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.expand(
            child: Builder(
              builder: (context) => page.transitionsBuilder(
                context,
                const AlwaysStoppedAnimation<double>(0.1),
                const AlwaysStoppedAnimation<double>(0.0),
                page.child,
              ),
            ),
          ),
        ),
      );

      final earlyFade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.byKey(childKey),
              matching: find.byType(FadeTransition),
            )
            .first,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.expand(
            child: Builder(
              builder: (context) => page.transitionsBuilder(
                context,
                const AlwaysStoppedAnimation<double>(0.6),
                const AlwaysStoppedAnimation<double>(0.0),
                page.child,
              ),
            ),
          ),
        ),
      );

      final delayedFade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.byKey(childKey),
              matching: find.byType(FadeTransition),
            )
            .first,
      );

      expect(earlyFade.opacity.value, equals(0.0));
      expect(delayedFade.opacity.value, greaterThan(0.0));
    },
  );

  testWidgets(
    'fade slide transition gives the covered route a head start before the incoming fade begins',
    (tester) async {
      const childKey = ValueKey('adaptive-covered-gap-child');
      final page = fadeSlideTransition(
        key: const ValueKey('adaptive-web'),
        child: const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(key: childKey, width: 120, height: 120),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.expand(
            child: Builder(
              builder: (context) => page.transitionsBuilder(
                context,
                const AlwaysStoppedAnimation<double>(1.0),
                const AlwaysStoppedAnimation<double>(0.18),
                page.child,
              ),
            ),
          ),
        ),
      );

      final outgoingFade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.byKey(childKey),
              matching: find.byType(FadeTransition),
            )
            .first,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.expand(
            child: Builder(
              builder: (context) => page.transitionsBuilder(
                context,
                const AlwaysStoppedAnimation<double>(0.18),
                const AlwaysStoppedAnimation<double>(0.0),
                page.child,
              ),
            ),
          ),
        ),
      );

      final incomingFade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.byKey(childKey),
              matching: find.byType(FadeTransition),
            )
            .first,
      );

      expect(outgoingFade.opacity.value, greaterThan(0.0));
      expect(incomingFade.opacity.value, equals(0.0));
    },
  );

  testWidgets(
    'fade slide transition overlaps incoming and covered routes mid-transition',
    (tester) async {
      const childKey = ValueKey('adaptive-overlap-child');
      final page = fadeSlideTransition(
        key: const ValueKey('adaptive-web'),
        child: const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(key: childKey, width: 120, height: 120),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.expand(
            child: Builder(
              builder: (context) => page.transitionsBuilder(
                context,
                const AlwaysStoppedAnimation<double>(0.3),
                const AlwaysStoppedAnimation<double>(0.0),
                page.child,
              ),
            ),
          ),
        ),
      );

      final incomingFade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.byKey(childKey),
              matching: find.byType(FadeTransition),
            )
            .first,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.expand(
            child: Builder(
              builder: (context) => page.transitionsBuilder(
                context,
                const AlwaysStoppedAnimation<double>(1.0),
                const AlwaysStoppedAnimation<double>(0.3),
                page.child,
              ),
            ),
          ),
        ),
      );

      final outgoingFade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.byKey(childKey),
              matching: find.byType(FadeTransition),
            )
            .first,
      );

      expect(incomingFade.opacity.value, greaterThan(0.0));
      expect(outgoingFade.opacity.value, greaterThan(0.0));
    },
  );

  testWidgets('fade slide transition fades and shifts the covered route', (
    tester,
  ) async {
    const childKey = ValueKey('adaptive-covered-child');
    final page = fadeSlideTransition(
      key: const ValueKey('adaptive-web'),
      child: const Align(
        alignment: Alignment.topLeft,
        child: SizedBox(key: childKey, width: 120, height: 120),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: Builder(
            builder: (context) => page.transitionsBuilder(
              context,
              const AlwaysStoppedAnimation<double>(1.0),
              const AlwaysStoppedAnimation<double>(0.25),
              page.child,
            ),
          ),
        ),
      ),
    );

    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byKey(childKey),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    final topLeft = tester.getTopLeft(find.byKey(childKey));

    expect(fade.opacity.value, lessThan(1.0));
    expect(fade.opacity.value, greaterThan(0.3));
    expect(topLeft.dx, lessThan(0.0));
  });

  test(
    'focusedFlowRoutePage returns CustomTransitionPage for focused flows',
    () {
      final page = focusedFlowRoutePage(
        key: const ValueKey('focused-web'),
        child: const SizedBox.shrink(),
        forceWebTransition: true,
      );

      expect(page, isA<CustomTransitionPage<void>>());
    },
  );

  test('focused flow transition uses the tuned longer page durations', () {
    final page =
        focusedFlowRoutePage(
              key: const ValueKey('focused-web'),
              child: const SizedBox.shrink(),
              forceWebTransition: true,
            )
            as CustomTransitionPage<void>;

    expect(page.transitionDuration, const Duration(milliseconds: 600));
    expect(page.reverseTransitionDuration, const Duration(milliseconds: 600));
  });

  testWidgets(
    'focused flow transition quickly fades the covered route without translating it',
    (tester) async {
      const childKey = ValueKey('focused-secondary-child');
      final page =
          focusedFlowRoutePage(
                key: const ValueKey('focused-web'),
                child: const Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(key: childKey, width: 120, height: 120),
                ),
                forceWebTransition: true,
              )
              as CustomTransitionPage<void>;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.expand(
            child: Builder(
              builder: (context) => page.transitionsBuilder(
                context,
                const AlwaysStoppedAnimation<double>(1.0),
                const AlwaysStoppedAnimation<double>(0.2),
                page.child,
              ),
            ),
          ),
        ),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      final topLeft = tester.getTopLeft(find.byKey(childKey));

      expect(opacity.opacity, equals(0.0));
      expect(topLeft.dx, equals(0.0));
    },
  );

  testWidgets(
    'focused flow transition starts revealing the incoming route early',
    (tester) async {
      const childKey = ValueKey('focused-incoming-child');
      final page =
          focusedFlowRoutePage(
                key: const ValueKey('focused-web'),
                child: const Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(key: childKey, width: 120, height: 120),
                ),
                forceWebTransition: true,
              )
              as CustomTransitionPage<void>;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.expand(
            child: Builder(
              builder: (context) => page.transitionsBuilder(
                context,
                const AlwaysStoppedAnimation<double>(0.05),
                const AlwaysStoppedAnimation<double>(0.0),
                page.child,
              ),
            ),
          ),
        ),
      );

      final preFade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.byKey(childKey),
              matching: find.byType(FadeTransition),
            )
            .first,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.expand(
            child: Builder(
              builder: (context) => page.transitionsBuilder(
                context,
                const AlwaysStoppedAnimation<double>(0.2),
                const AlwaysStoppedAnimation<double>(0.0),
                page.child,
              ),
            ),
          ),
        ),
      );

      final earlyFade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.byKey(childKey),
              matching: find.byType(FadeTransition),
            )
            .first,
      );

      expect(preFade.opacity.value, equals(0.0));
      expect(earlyFade.opacity.value, greaterThan(0.0));
    },
  );
}
