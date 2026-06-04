import 'package:flutter/material.dart';

import '../../../../shared/widgets/weekly_availability_editor.dart';

class GamingHoursEditor extends StatefulWidget {
  const GamingHoursEditor({super.key, this.initialHours, this.onChanged});

  final Map<String, dynamic>? initialHours;
  final ValueChanged<Map<String, dynamic>>? onChanged;

  @override
  State<GamingHoursEditor> createState() => _GamingHoursEditorState();
}

class _GamingHoursEditorState extends State<GamingHoursEditor> {
  @override
  Widget build(BuildContext context) {
    return WeeklyAvailabilityEditor(
      initialHours: widget.initialHours,
      onChanged: widget.onChanged,
    );
  }
}
