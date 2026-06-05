import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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

Page<void> focusedFlowRoutePage({
  required LocalKey key,
  required Widget child,
  bool forceWebTransition = false,
}) {
  if (forceWebTransition || kIsWeb) {
    return focusedFlowTransitionPage(key: key, child: child);
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => CupertinoPage<void>(key: key, child: child),
    _ => MaterialPage<void>(key: key, child: child),
  };
}

CustomTransitionPage<void> focusedFlowTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 600),
    reverseTransitionDuration: const Duration(milliseconds: 600),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final incomingFade = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.08, 0.5, curve: Curves.easeIn),
      );
      final fadeOut = CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.18, curve: Curves.easeIn),
      );

      final isCoveredRoute = secondaryAnimation.value > 0.0;

      if (isCoveredRoute) {
        return AnimatedBuilder(
          animation: fadeOut,
          child: child,
          builder: (context, child) {
            return Opacity(
              opacity: (1.0 - fadeOut.value).clamp(0.0, 1.0),
              child: child,
            );
          },
        );
      }

      return FadeTransition(opacity: incomingFade, child: child);
    },
  );
}

CustomTransitionPage<void> fadeSlideTransition({
  required LocalKey key,
  required Widget child,
  Offset beginOffset = const Offset(0.03, 0),
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final incomingSlide = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final incomingFade = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
      );
      final outgoingFade = CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      );
      final outgoingSlide = CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      );

      final isCoveredRoute = secondaryAnimation.value > 0.0;

      if (isCoveredRoute) {
        return FadeTransition(
          opacity: ReverseAnimation(outgoingFade),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.03, 0),
            ).animate(outgoingSlide),
            child: child,
          ),
        );
      }

      return FadeTransition(
        opacity: incomingFade,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(incomingSlide),
          child: child,
        ),
      );
    },
  );
}
