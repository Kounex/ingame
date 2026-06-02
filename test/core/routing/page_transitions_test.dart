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
}
