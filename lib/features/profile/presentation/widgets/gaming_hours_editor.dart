import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';

class GamingHoursEditor extends StatefulWidget {
  const GamingHoursEditor({
    super.key,
    this.initialHours,
    this.onChanged,
  });

  final Map<String, dynamic>? initialHours;
  final ValueChanged<Map<String, dynamic>>? onChanged;

  @override
  State<GamingHoursEditor> createState() => _GamingHoursEditorState();
}

class _GamingHoursEditorState extends State<GamingHoursEditor> {
  static const _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  late Map<String, dynamic> _hours;

  @override
  void initState() {
    super.initState();
    _hours = Map<String, dynamic>.from(widget.initialHours ?? {});
  }

  String _formatHours(String day) {
    final dayHours = _hours[day];
    if (dayHours == null || (dayHours is List && dayHours.isEmpty)) {
      return 'Not set';
    }
    if (dayHours is List && dayHours.isNotEmpty) {
      final slot = dayHours.first as Map<String, dynamic>;
      return '${slot['start']} - ${slot['end']}';
    }
    return 'Not set';
  }

  Future<void> _editDay(int index) async {
    final day = _days[index];
    final result = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
      helpText: 'Select start time for ${_dayLabels[index]}',
    );
    if (result != null && mounted) {
      final endResult = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: (result.hour + 4) % 24, minute: 0),
        helpText: 'Select end time for ${_dayLabels[index]}',
      );
      if (endResult != null && mounted) {
        setState(() {
          _hours[day] = [
            {
              'start':
                  '${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}',
              'end':
                  '${endResult.hour.toString().padLeft(2, '0')}:${endResult.minute.toString().padLeft(2, '0')}',
            }
          ];
        });
        widget.onChanged?.call(_hours);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gaming Hours',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(_days.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: GlassCard(
              onTap: () => _editDay(index),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dayLabels[index],
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatHours(_days[index]),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
