import 'package:flutter/material.dart';

import '../../core/theme/spacing.dart';
import 'tappable.dart';

class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.gap = AppSpacing.md,
  });

  final Widget title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final CrossAxisAlignment crossAxisAlignment;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: contentPadding ?? EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          if (leading != null) ...[leading!, SizedBox(width: gap)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                title,
                if (subtitle != null) ...[const SizedBox(height: 2), subtitle!],
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: gap), trailing!],
        ],
      ),
    );

    if (onTap == null) return row;
    return Tappable(onTap: onTap, child: row);
  }
}
