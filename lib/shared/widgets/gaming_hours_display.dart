import 'package:flutter/material.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';
import '../../core/utils/extensions.dart';
import 'app_chip.dart';
import 'weekly_availability_editor.dart';

class GamingHoursDisplay extends StatelessWidget {
  const GamingHoursDisplay({super.key, required this.gamingHours});

  final Map<String, dynamic>? gamingHours;

  static const _dayOrder = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  String _formatSlot(Map<String, dynamic> slot) {
    final start = slot['start'] as String? ?? '';
    final end = slot['end'] as String? ?? '';
    return '$start-$end';
  }

  String _readableTime(BuildContext context, String t) {
    final parts = t.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: hour, minute: minute),
      alwaysUse24HourFormat:
          MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
    );
  }

  List<_ScheduleGroup> _buildGroups(BuildContext context) {
    if (gamingHours == null || gamingHours!.isEmpty) return [];

    final daySlots = <String, List<String>>{};
    for (final day in _dayOrder) {
      final raw = gamingHours![day];
      if (raw == null) continue;
      final slots = (raw as List<dynamic>).cast<Map<String, dynamic>>();
      daySlots[day] = slots.map(_formatSlot).toList()..sort();
    }

    final signatureToGroup = <String, List<String>>{};
    for (final day in _dayOrder) {
      final slots = daySlots[day];
      if (slots == null || slots.isEmpty) continue;
      final sig = slots.join('|');
      signatureToGroup.putIfAbsent(sig, () => []).add(day);
    }

    return signatureToGroup.entries.map((e) {
      final slotKeys = e.key.split('|');
      final presetKeys = slotKeys
          .map(weeklyAvailabilityPresetFromSerializedRange)
          .whereType<String>()
          .toSet();
      final slotLabels =
          weeklyAvailabilityHasAllDay(presetKeys) &&
              presetKeys.length == weeklyAvailabilityPresetOrder.length
          ? <String>[context.l10n.timeSlotAllDayLabel]
          : slotKeys.map((key) {
              final name = _slotName(context, key);
              if (name != null) return name;
              final parts = key.split('-');
              return '${_readableTime(context, parts[0])} – ${_readableTime(context, parts[1])}';
            }).toList();
      return _ScheduleGroup(
        days: e.value,
        slots: slotLabels,
        slotKeys: slotKeys,
      );
    }).toList();
  }

  String _daysLabel(List<String> days) {
    final l10n = currentAppLocalizations();
    if (days.length == 7) return l10n.profileEveryDay;
    if (days.length == 5 &&
        days.every((d) => !['saturday', 'sunday'].contains(d))) {
      return l10n.profileWeekdays;
    }
    if (days.length == 2 &&
        days.every((d) => ['saturday', 'sunday'].contains(d))) {
      return l10n.profileWeekends;
    }
    return days.map(_dayLabel).join(', ');
  }

  String _dayLabel(String day) {
    final l10n = currentAppLocalizations();
    return switch (day) {
      'monday' => l10n.dayMonShort,
      'tuesday' => l10n.dayTueShort,
      'wednesday' => l10n.dayWedShort,
      'thursday' => l10n.dayThuShort,
      'friday' => l10n.dayFriShort,
      'saturday' => l10n.daySatShort,
      'sunday' => l10n.daySunShort,
      _ => day,
    };
  }

  String? _slotName(BuildContext context, String key) {
    final preset = weeklyAvailabilityPresetFromSerializedRange(key);
    if (preset == null) return null;
    return weeklyAvailabilityPresetLabel(context, preset);
  }

  IconData? _slotIcon(String slotKey) {
    final preset = weeklyAvailabilityPresetFromSerializedRange(slotKey);
    if (preset == null) return null;
    return weeklyAvailabilityPresetIcon(preset);
  }

  @override
  Widget build(BuildContext context) {
    final groups = _buildGroups(context);

    if (groups.isEmpty) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.glassSurfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.schedule_outlined,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            context.l10n.profileNoSchedule,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups) ...[
          if (group != groups.first)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Divider(height: 1),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _daysLabel(group.days),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (var i = 0; i < group.slots.length; i++)
                      _SlotChip(
                        label: group.slots[i],
                        icon: group.slots[i] ==
                                context.l10n.timeSlotAllDayLabel
                            ? weeklyAvailabilityPresetIcon('all-day')
                            : _slotIcon(group.slotKeys[i]),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ScheduleGroup {
  const _ScheduleGroup({
    required this.days,
    required this.slots,
    required this.slotKeys,
  });

  final List<String> days;
  final List<String> slots;
  final List<String> slotKeys;
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppChip.accent(label: label, icon: icon, color: AppColors.primary);
  }
}
