import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Timezone',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _commonTimezones.contains(selectedTimezone)
                  ? selectedTimezone
                  : _commonTimezones.first,
              isExpanded: true,
              dropdownColor: AppColors.backgroundLight,
              style: const TextStyle(color: AppColors.textPrimary),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.textTertiary,
              ),
              items: _commonTimezones.map((tz) {
                return DropdownMenuItem(
                  value: tz,
                  child: Text(
                    tz.replaceAll('_', ' '),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
            ),
          ),
        ),
      ],
    );
  }
}
