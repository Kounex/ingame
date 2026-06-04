import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/spacing.dart';

enum DesktopContentWidth {
  compact(560),
  form(720),
  reading(960),
  wide(1120),
  full(null);

  const DesktopContentWidth(this.maxWidth);

  final double? maxWidth;
}

class DesktopContentRegion extends StatelessWidget {
  const DesktopContentRegion({
    super.key,
    required this.width,
    required this.child,
  });

  final DesktopContentWidth width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = width.maxWidth;
        final shouldClamp =
            maxWidth != null &&
            constraints.maxWidth >= AppBreakpoints.sidebar &&
            constraints.maxWidth > maxWidth;
        final double horizontalPadding = shouldClamp
            ? math.max<double>(0.0, (constraints.maxWidth - maxWidth) / 2)
            : 0.0;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: child,
        );
      },
    );
  }
}
