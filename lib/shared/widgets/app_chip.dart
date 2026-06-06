import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';

enum _AppChipKind { inline, surface, accent }

class AppChip extends StatelessWidget {
  const AppChip.inline({super.key, required this.label, this.icon})
    : _kind = _AppChipKind.inline,
      backgroundColor = null,
      borderColor = null,
      _accentColor = null,
      _textColor = AppColors.textSecondary,
      _iconColor = AppColors.textTertiary,
      _fontSize = 13,
      _fontWeight = FontWeight.w400,
      _padding = EdgeInsets.zero,
      _borderRadius = BorderRadius.zero;

  const AppChip.surface({
    super.key,
    required this.label,
    this.icon,
    bool compact = false,
    this.backgroundColor = AppColors.glassSurfaceLight,
    this.borderColor = AppColors.glassBorder,
    Color textColor = AppColors.textSecondary,
    Color? iconColor,
  }) : _kind = _AppChipKind.surface,
       _accentColor = null,
       _textColor = textColor,
       _iconColor = iconColor ?? textColor,
       _fontSize = compact ? 12 : 13,
       _fontWeight = compact ? FontWeight.w500 : FontWeight.w400,
       _padding = compact
           ? const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6)
           : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
       _borderRadius = const BorderRadius.all(Radius.circular(999));

  const AppChip.accent({
    super.key,
    required this.label,
    required Color color,
    this.icon,
    bool compact = false,
  }) : _kind = _AppChipKind.accent,
       backgroundColor = null,
       borderColor = null,
       _accentColor = color,
       _textColor = color,
       _iconColor = color,
       _fontSize = compact ? 12 : 13,
       _fontWeight = FontWeight.w500,
       _padding = compact
           ? const EdgeInsets.symmetric(
               horizontal: AppSpacing.sm,
               vertical: AppSpacing.xs + 1,
             )
           : const EdgeInsets.symmetric(
               horizontal: AppSpacing.sm + 2,
               vertical: AppSpacing.xs + 2,
             ),
       _borderRadius = const BorderRadius.all(Radius.circular(20));

  final String label;
  final IconData? icon;
  final _AppChipKind _kind;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? _accentColor;
  final Color _textColor;
  final Color _iconColor;
  final double _fontSize;
  final FontWeight _fontWeight;
  final EdgeInsetsGeometry _padding;
  final BorderRadius _borderRadius;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: _fontSize + 1, color: _iconColor),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            color: _textColor,
            fontSize: _fontSize,
            fontWeight: _fontWeight,
          ),
        ),
      ],
    );

    if (_kind == _AppChipKind.inline) return child;

    final resolvedBackgroundColor = switch (_kind) {
      _AppChipKind.surface => backgroundColor!,
      _AppChipKind.accent => _accentColor!.withValues(alpha: 0.1),
      _AppChipKind.inline => null,
    };
    final resolvedBorderColor = switch (_kind) {
      _AppChipKind.surface => borderColor,
      _AppChipKind.accent => _accentColor!.withValues(alpha: 0.25),
      _AppChipKind.inline => null,
    };

    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: resolvedBackgroundColor,
        borderRadius: _borderRadius,
        border: resolvedBorderColor == null
            ? null
            : Border.all(color: resolvedBorderColor),
      ),
      child: child,
    );
  }
}
