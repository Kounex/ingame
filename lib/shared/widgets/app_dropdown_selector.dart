import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';
import '../services/app_haptics.dart';

class AppDropdownOption<T> {
  const AppDropdownOption({
    required this.value,
    required this.label,
    this.menuItemKey,
  });

  final T value;
  final String label;
  final Key? menuItemKey;
}

enum _AppDropdownKind { surface, field }

class AppDropdownSelector<T> extends ConsumerWidget {
  const AppDropdownSelector.surface({
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon,
    this.tooltip,
    super.key,
    this.compact = false,
    this.backgroundColor = AppColors.glassSurface,
    this.borderColor = AppColors.glassBorder,
    this.closedTextColor = AppColors.textPrimary,
    this.closedTextStyle,
  }) : _kind = _AppDropdownKind.surface,
       labelText = null;

  const AppDropdownSelector.field({
    required this.value,
    required this.options,
    required this.onChanged,
    required this.labelText,
    super.key,
  }) : _kind = _AppDropdownKind.field,
       icon = null,
       tooltip = null,
       compact = false,
       backgroundColor = AppColors.glassSurface,
       borderColor = AppColors.glassBorder,
       closedTextColor = AppColors.textPrimary,
       closedTextStyle = null;

  final _AppDropdownKind _kind;
  final T value;
  final List<AppDropdownOption<T>> options;
  final ValueChanged<T> onChanged;
  final String? labelText;

  final IconData? icon;
  final String? tooltip;
  final bool compact;
  final Color backgroundColor;
  final Color borderColor;
  final Color closedTextColor;
  final TextStyle? closedTextStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final haptics = ref.read(appHapticsProvider);
    final dropdown = ButtonTheme(
      alignedDropdown: true,
      child: Theme(
        data: Theme.of(context).copyWith(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          focusColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: _kind == _AppDropdownKind.surface
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? AppSpacing.sm + 2 : AppSpacing.md,
                    vertical: AppSpacing.xs + 2,
                  ),
                  child: _buildDropdown(context, haptics),
                ),
              )
            : _buildDropdown(context, haptics),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) {
      return dropdown;
    }

    return Tooltip(message: tooltip!, child: dropdown);
  }

  DropdownButtonFormField<T> _buildDropdown(
    BuildContext context,
    AppHaptics haptics,
  ) {
    return DropdownButtonFormField<T>(
      value: value,
      isDense: true,
      isExpanded: true,
      icon: const Icon(
        Icons.arrow_drop_down,
        color: AppColors.textTertiary,
        size: 18,
      ),
      decoration: _kind == _AppDropdownKind.field
          ? InputDecoration(labelText: labelText)
          : InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              prefixIcon: icon == null
                  ? null
                  : Icon(icon, color: AppColors.textTertiary, size: 16),
              prefixIconConstraints: icon == null
                  ? null
                  : const BoxConstraints(minWidth: 20, minHeight: 16),
            ),
      dropdownColor: AppColors.backgroundLight,
      borderRadius: BorderRadius.circular(18),
      onTap: haptics.selection,
      selectedItemBuilder: (context) {
        return options
            .map(
              (option) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  option.label,
                  overflow: TextOverflow.ellipsis,
                  style:
                      closedTextStyle ??
                      TextStyle(
                        color: closedTextColor,
                        fontSize: _kind == _AppDropdownKind.field ? 14 : 13,
                        fontWeight: _kind == _AppDropdownKind.field
                            ? FontWeight.w500
                            : FontWeight.w600,
                      ),
                ),
              ),
            )
            .toList();
      },
      items: options.map((option) {
        return DropdownMenuItem<T>(
          key: option.menuItemKey,
          value: option.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: _DropdownMenuItemRow(
              label: option.label,
              selected: option.value == value,
            ),
          ),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue == null) return;
        haptics.selection();
        onChanged(newValue);
      },
    );
  }
}

class _DropdownMenuItemRow extends StatelessWidget {
  const _DropdownMenuItemRow({
    required this.label,
    required this.selected,
  });

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
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
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
