import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _cupertinoPushFadeInterval = Interval(0.08, 0.5, curve: Curves.easeIn);
const _cupertinoCoveredFadeInterval = Interval(0.0, 0.22, curve: Curves.easeIn);

double cupertinoRoutePrimaryOpacity({
  required double animationValue,
  required AnimationStatus status,
}) {
  final clamped = animationValue.clamp(0.0, 1.0);
  if (status == AnimationStatus.reverse) {
    return Curves.easeIn.transform(clamped);
  }

  return _cupertinoPushFadeInterval.transform(clamped);
}

double cupertinoCoveredRouteOpacity({required double secondaryAnimationValue}) {
  final clamped = secondaryAnimationValue.clamp(0.0, 1.0);
  return 1.0 - _cupertinoCoveredFadeInterval.transform(clamped);
}

class CupertinoFadePage<T> extends Page<T> {
  const CupertinoFadePage({
    required this.child,
    required super.key,
    this.maintainState = true,
    this.fullscreenDialog = false,
    this.fadeIncoming = true,
    this.transitionDuration = const Duration(milliseconds: 420),
    this.reverseTransitionDuration = const Duration(milliseconds: 420),
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final bool maintainState;
  final bool fullscreenDialog;
  final bool fadeIncoming;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  @override
  Route<T> createRoute(BuildContext context) {
    return _CupertinoFadePageRoute<T>(page: this);
  }
}

class _CupertinoFadePageRoute<T> extends CupertinoPageRoute<T> {
  _CupertinoFadePageRoute({required this.page})
    : super(
        settings: page,
        builder: (_) => page.child,
        maintainState: page.maintainState,
        fullscreenDialog: page.fullscreenDialog,
      );

  final CupertinoFadePage<T> page;
  CupertinoFadePage<T> get _currentPage => settings as CupertinoFadePage<T>;

  @override
  Duration get transitionDuration => _currentPage.transitionDuration;

  @override
  Duration get reverseTransitionDuration =>
      _currentPage.reverseTransitionDuration;

  @override
  Widget buildContent(BuildContext context) {
    return _currentPage.child;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final transitionedChild = super.buildTransitions(
      context,
      animation,
      secondaryAnimation,
      child,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: transitionedChild,
      builder: (context, child) {
        final isCoveredRoute = secondaryAnimation.value > 0.0;
        final shouldFadeIncoming = _currentPage.fadeIncoming;
        final opacity = isCoveredRoute
            ? cupertinoCoveredRouteOpacity(
                secondaryAnimationValue: secondaryAnimation.value,
              )
            : shouldFadeIncoming
            ? cupertinoRoutePrimaryOpacity(
                animationValue: animation.value,
                status: animation.status,
              )
            : 1.0;
        return Opacity(opacity: opacity.clamp(0.0, 1.0), child: child);
      },
    );
  }
}

Page<void> adaptiveRoutePage({required LocalKey key, required Widget child}) {
  if (kIsWeb) {
    return fadeSlideTransition(key: key, child: child);
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => CupertinoFadePage<void>(key: key, child: child),
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
    TargetPlatform.iOS => CupertinoFadePage<void>(
      key: key,
      child: child,
      fadeIncoming: false,
    ),
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
      final incomingSlide = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.18, 0.62, curve: Curves.easeOutCubic),
      );
      final incomingFade = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.18, 0.56, curve: Curves.easeIn),
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

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.02, 0),
          end: Offset.zero,
        ).animate(incomingSlide),
        child: FadeTransition(opacity: incomingFade, child: child),
      );
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
