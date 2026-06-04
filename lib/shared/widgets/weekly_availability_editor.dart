import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_components.dart';
import '../../core/theme/spacing.dart';
import '../../core/utils/extensions.dart';

const weeklyAvailabilityDayOrder = <String>[
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

const weeklyAvailabilityPresetOrder = <String>[
  'morning',
  'afternoon',
  'evening',
  'night',
];

const weeklyAvailabilityPresetRanges = <String, Map<String, String>>{
  'morning': {'start': '06:00', 'end': '12:00'},
  'afternoon': {'start': '12:00', 'end': '18:00'},
  'evening': {'start': '18:00', 'end': '00:00'},
  'night': {'start': '00:00', 'end': '06:00'},
};

const _allDayPresetKey = 'all-day';

String weeklyAvailabilitySerializeRange(String start, String end) {
  return '$start-$end';
}

Map<String, Set<String>> decodeWeeklyAvailabilityHours(
  Map<String, dynamic>? hours,
) {
  final decoded = <String, Set<String>>{};
  if (hours == null || hours.isEmpty) return decoded;

  for (final day in weeklyAvailabilityDayOrder) {
    final raw = hours[day];
    if (raw is! List) continue;

    final selected = <String>{};
    for (final entry in raw) {
      if (entry is! Map) continue;
      final start = entry['start'] as String?;
      final end = entry['end'] as String?;
      if (start == null || end == null) continue;
      final key = weeklyAvailabilityPresetOrder.cast<String?>().firstWhere((
        slotKey,
      ) {
        if (slotKey == null) return false;
        final range = weeklyAvailabilityPresetRanges[slotKey]!;
        return range['start'] == start && range['end'] == end;
      }, orElse: () => null);
      selected.add(key ?? weeklyAvailabilitySerializeRange(start, end));
    }

    if (selected.isNotEmpty) {
      decoded[day] = selected;
    }
  }

  return decoded;
}

Map<String, dynamic> buildWeeklyAvailabilityHours(
  Map<String, Set<String>> selectedByDay,
) {
  final encoded = <String, dynamic>{};

  for (final day in weeklyAvailabilityDayOrder) {
    final selected = selectedByDay[day];
    if (selected == null || selected.isEmpty) continue;

    final customKeys = selected
        .where((slotKey) => !weeklyAvailabilityPresetOrder.contains(slotKey))
        .toList()
      ..sort();
    final orderedKeys = [
      for (final slotKey in weeklyAvailabilityPresetOrder)
        if (selected.contains(slotKey)) slotKey,
      ...customKeys,
    ];

    final dayRanges = <Map<String, String>>[];
    for (final slotKey in orderedKeys) {
      final range = weeklyAvailabilityRangeForKey(slotKey);
      if (range != null) {
        dayRanges.add(Map<String, String>.from(range));
      }
    }

    if (dayRanges.isNotEmpty) {
      encoded[day] = dayRanges;
    }
  }

  return encoded;
}

bool weeklyAvailabilityHasAllDay(Set<String> selected) {
  return weeklyAvailabilityPresetOrder.every(selected.contains);
}

String? weeklyAvailabilityPresetFromRange(String start, String end) {
  for (final slotKey in weeklyAvailabilityPresetOrder) {
    final range = weeklyAvailabilityPresetRanges[slotKey]!;
    if (range['start'] == start && range['end'] == end) {
      return slotKey;
    }
  }
  return null;
}

String? weeklyAvailabilityPresetFromSerializedRange(String key) {
  final parts = key.split('-');
  if (parts.length != 2) return null;
  return weeklyAvailabilityPresetFromRange(parts[0], parts[1]);
}

Map<String, String>? weeklyAvailabilityRangeForKey(String slotKey) {
  final presetRange = weeklyAvailabilityPresetRanges[slotKey];
  if (presetRange != null) {
    return presetRange;
  }

  final parts = slotKey.split('-');
  if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
    return null;
  }

  return {'start': parts[0], 'end': parts[1]};
}

String weeklyAvailabilityReadableTime(String t) {
  if (t == '00:00') return '12 AM';
  final parts = t.split(':');
  final hour = int.tryParse(parts[0]) ?? 0;
  if (hour == 0) return '12 AM';
  if (hour == 12) return '12 PM';
  if (hour > 12) return '${hour - 12} PM';
  return '$hour AM';
}

String weeklyAvailabilityDayLabel(BuildContext context, String day) {
  final l10n = context.l10n;
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

String weeklyAvailabilityPresetLabel(BuildContext context, String preset) {
  final l10n = context.l10n;
  return switch (preset) {
    'morning' => l10n.timeSlotMorningLabel,
    'afternoon' => l10n.timeSlotAfternoonLabel,
    'evening' => l10n.timeSlotEveningLabel,
    'night' => l10n.timeSlotNightLabel,
    _allDayPresetKey => l10n.timeSlotAllDayLabel,
    _ => preset,
  };
}

String weeklyAvailabilitySlotLabel(BuildContext context, String slotKey) {
  if (slotKey == _allDayPresetKey) {
    return weeklyAvailabilityPresetLabel(context, slotKey);
  }

  final preset = weeklyAvailabilityPresetFromSerializedRange(slotKey);
  if (preset != null) {
    return weeklyAvailabilityPresetLabel(context, preset);
  }

  final parts = slotKey.split('-');
  if (parts.length != 2) return slotKey;
  return '${weeklyAvailabilityReadableTime(parts[0])} – ${weeklyAvailabilityReadableTime(parts[1])}';
}

String? weeklyAvailabilityPresetSubtitle(BuildContext context, String preset) {
  final l10n = context.l10n;
  return switch (preset) {
    'morning' => l10n.timeSlotMorningSubtitle,
    'afternoon' => l10n.timeSlotAfternoonSubtitle,
    'evening' => l10n.timeSlotEveningSubtitle,
    'night' => l10n.timeSlotNightSubtitle,
    _allDayPresetKey => l10n.timeSlotAllDaySubtitle,
    _ => null,
  };
}

IconData weeklyAvailabilityPresetIcon(String preset) {
  return switch (preset) {
    'morning' => Icons.wb_sunny_outlined,
    'afternoon' => Icons.wb_cloudy_outlined,
    'evening' => Icons.nights_stay_outlined,
    'night' => Icons.dark_mode_outlined,
    _allDayPresetKey => Icons.schedule_outlined,
    _ => Icons.schedule_outlined,
  };
}

class WeeklyAvailabilityEditor extends StatefulWidget {
  const WeeklyAvailabilityEditor({
    super.key,
    this.initialHours,
    this.onChanged,
    this.showTitle = true,
  });

  final Map<String, dynamic>? initialHours;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final bool showTitle;

  @override
  State<WeeklyAvailabilityEditor> createState() =>
      _WeeklyAvailabilityEditorState();
}

class _WeeklyAvailabilityEditorState extends State<WeeklyAvailabilityEditor> {
  late Map<String, Set<String>> _selectedByDay;

  @override
  void initState() {
    super.initState();
    _selectedByDay = decodeWeeklyAvailabilityHours(widget.initialHours);
  }

  void _togglePreset(String day, String preset) {
    final next = <String, Set<String>>{
      for (final entry in _selectedByDay.entries)
        entry.key: Set<String>.from(entry.value),
    };

    final selected = next.putIfAbsent(day, () => <String>{});

    if (preset == _allDayPresetKey) {
      if (weeklyAvailabilityHasAllDay(selected)) {
        selected.clear();
      } else {
        selected
          ..clear()
          ..addAll(weeklyAvailabilityPresetOrder);
      }
    } else if (selected.contains(preset)) {
      selected.remove(preset);
    } else {
      selected.add(preset);
    }

    if (selected.isEmpty) {
      next.remove(day);
    }

    setState(() {
      _selectedByDay = next;
    });
    widget.onChanged?.call(buildWeeklyAvailabilityHours(next));
  }

  bool _isSelected(String day, String preset) {
    final selected = _selectedByDay[day] ?? const <String>{};
    if (preset == _allDayPresetKey) {
      return weeklyAvailabilityHasAllDay(selected);
    }
    return selected.contains(preset);
  }

  List<String> _chipKeysForDay(String day) {
    final selected = _selectedByDay[day] ?? const <String>{};
    final customSlots = selected
        .where((slotKey) => !weeklyAvailabilityPresetOrder.contains(slotKey))
        .toList()
      ..sort();

    return <String>[
      ...weeklyAvailabilityPresetOrder,
      ...customSlots,
      _allDayPresetKey,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          Text(
            context.l10n.gamingHoursTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (final day in weeklyAvailabilityDayOrder)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: GlassCard(
              key: Key('weekly-availability-row-$day'),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weeklyAvailabilityDayLabel(context, day),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final preset in _chipKeysForDay(day))
                        FilterChip(
                          key: Key('weekly-availability-chip-$day-$preset'),
                          selected: _isSelected(day, preset),
                          onSelected: (_) => _togglePreset(day, preset),
                          avatar: Icon(
                            weeklyAvailabilityPresetIcon(preset),
                            size: 18,
                            color: _isSelected(day, preset)
                                ? AppColors.background
                                : AppColors.textTertiary,
                          ),
                          label: Text(
                            weeklyAvailabilitySlotLabel(context, preset),
                          ),
                          tooltip: weeklyAvailabilityPresetSubtitle(
                            context,
                            preset,
                          ),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.glassSurfaceLight,
                          checkmarkColor: AppColors.background,
                          side: BorderSide(
                            color: _isSelected(day, preset)
                                ? AppColors.primary
                                : AppColors.glassBorder,
                          ),
                          labelStyle: TextStyle(
                            color: _isSelected(day, preset)
                                ? AppColors.background
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
