import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../services/app_haptics.dart';

class AppRefreshIndicator extends ConsumerStatefulWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  ConsumerState<AppRefreshIndicator> createState() =>
      _AppRefreshIndicatorState();
}

class _AppRefreshIndicatorState extends ConsumerState<AppRefreshIndicator> {
  double _dragOffset = 0;
  bool _hapticFired = false;

  static const double _kDragContainerExtentPercentage = 0.25;
  static const double _kDragSizeFactorLimit = 1.5;

  void _checkArmed(double viewportDimension) {
    if (_hapticFired) return;
    final threshold = viewportDimension *
        _kDragContainerExtentPercentage /
        _kDragSizeFactorLimit;
    if (_dragOffset >= threshold) {
      _hapticFired = true;
      ref.read(appHapticsProvider).success();
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    switch (notification) {
      case ScrollStartNotification():
        _dragOffset = 0;
        _hapticFired = false;
      case ScrollUpdateNotification(:final scrollDelta):
        // iOS bouncing physics: scroll position goes past the boundary
        // instead of emitting OverscrollNotification.
        if (notification.metrics.extentBefore == 0 &&
            scrollDelta != null &&
            scrollDelta < 0) {
          _dragOffset -= scrollDelta;
          _checkArmed(notification.metrics.viewportDimension);
        } else if (notification.metrics.extentBefore > 0) {
          _dragOffset = 0;
          _hapticFired = false;
        }
      case OverscrollNotification(:final overscroll):
        // Android clamping physics: overscroll is reported separately.
        if (overscroll < 0) {
          _dragOffset -= overscroll;
          _checkArmed(notification.metrics.viewportDimension);
        }
      case ScrollEndNotification():
        _dragOffset = 0;
        _hapticFired = false;
      default:
        break;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.glassSurfaceLight,
        strokeWidth: 2.5,
        onRefresh: widget.onRefresh,
        child: widget.child,
      ),
    );
  }
}
