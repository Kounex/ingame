import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Page<void> adaptiveRoutePage({required LocalKey key, required Widget child}) {
  if (kIsWeb) {
    return fadeSlideTransition(key: key, child: child);
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => CupertinoPage<void>(key: key, child: child),
    _ => MaterialPage<void>(key: key, child: child),
  };
}

CustomTransitionPage<void> fadeSlideTransition({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
