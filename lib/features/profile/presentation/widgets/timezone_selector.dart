import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_anchored_popover_selector.dart';

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

  String get _resolvedTimezone => selectedTimezone.trim().isEmpty
      ? _commonTimezones.first
      : selectedTimezone;

  List<String> get _timezones => [
    if (!_commonTimezones.contains(_resolvedTimezone)) _resolvedTimezone,
    ..._commonTimezones,
  ];

  @override
  Widget build(BuildContext context) {
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
        AppAnchoredPopoverSelector<String>(
          value: _resolvedTimezone,
          tooltip: context.l10n.timezoneLabel,
          options: _timezones
              .map(
                (timezone) => AppAnchoredPopoverOption(
                  value: timezone,
                  label: _labelFor(timezone),
                  key: ValueKey('timezone-option-$timezone'),
                ),
              )
              .toList(),
          onSelected: onChanged,
          triggerBuilder: (context, togglePopover, isOpen) {
            return FocusableActionDetector(
              mouseCursor: SystemMouseCursors.click,
              shortcuts: const <ShortcutActivator, Intent>{
                SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
              },
              actions: <Type, Action<Intent>>{
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    togglePopover();
                    return null;
                  },
                ),
              },
              child: Semantics(
                button: true,
                child: GestureDetector(
                  key: const ValueKey('timezone-selector-trigger'),
                  onTap: togglePopover,
                  behavior: HitTestBehavior.opaque,
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
            );
          },
          itemBuilder: (context, option, selected) {
            return AppAnchoredPopoverMenuItem(
              label: option.label,
              selected: selected,
            );
          },
        ),
      ],
    );
  }

  String _labelFor(String timezone) => timezone.replaceAll('_', ' ');
}
