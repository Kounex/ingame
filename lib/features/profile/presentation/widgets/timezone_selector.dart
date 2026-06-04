import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';

class TimezoneSelector extends StatelessWidget {
  const TimezoneSelector({
    super.key,
    required this.selectedTimezone,
    required this.onChanged,
  });

  final String selectedTimezone;
  final ValueChanged<String> onChanged;

  static const _commonTimezones = [
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Sao_Paulo',
    'Europe/London',
    'Europe/Berlin',
    'Europe/Paris',
    'Europe/Moscow',
    'Asia/Tokyo',
    'Asia/Shanghai',
    'Asia/Kolkata',
    'Asia/Dubai',
    'Australia/Sydney',
    'Pacific/Auckland',
  ];

  String get _resolvedTimezone => _commonTimezones.contains(selectedTimezone)
      ? selectedTimezone
      : _commonTimezones.first;

  @override
  Widget build(BuildContext context) {
    final popupTheme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.timezoneLabel,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Theme(
          data: popupTheme.copyWith(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            focusColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
          ),
          child: PopupMenuButton<String>(
            key: const ValueKey('timezone-selector-trigger'),
            tooltip: context.l10n.timezoneLabel,
            offset: const Offset(0, 8),
            onSelected: onChanged,
            itemBuilder: (context) {
              return _commonTimezones.map((timezone) {
                final isSelected = timezone == _resolvedTimezone;
                return PopupMenuItem<String>(
                  key: ValueKey('timezone-option-$timezone'),
                  value: timezone,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: _TimezoneMenuItem(
                    label: _labelFor(timezone),
                    selected: isSelected,
                  ),
                );
              }).toList();
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _labelFor(_resolvedTimezone),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.textTertiary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _labelFor(String timezone) => timezone.replaceAll('_', ' ');
}

class _TimezoneMenuItem extends StatelessWidget {
  const _TimezoneMenuItem({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.28)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (selected)
            const Icon(Icons.check_rounded, color: AppColors.primary, size: 18),
        ],
      ),
    );
  }
}
