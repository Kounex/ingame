import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';
import '../../core/utils/extensions.dart';
import '../../l10n/app_localizations.dart';
import 'app_anchored_popover_selector.dart';

enum LanguageSwitcherMode { compact, settingsRow }

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({required this.mode, super.key});

  final LanguageSwitcherMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(resolvedLocaleProvider);
    final selectedLocale = _supportedLocale(locale);

    return switch (mode) {
      LanguageSwitcherMode.compact => Align(
        alignment: Alignment.centerRight,
        child: _LanguageMenuButton(
          key: const ValueKey('language-switcher-compact-trigger'),
          selectedLocale: selectedLocale,
          mode: mode,
          onSelected: (value) => _setLocale(ref, value),
        ),
      ),
      LanguageSwitcherMode.settingsRow => Row(
        children: [
          const Icon(
            Icons.language_outlined,
            color: AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              context.l10n.languageSwitcherLabel,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _LanguageMenuButton(
            key: const ValueKey('language-switcher-settings-trigger'),
            selectedLocale: selectedLocale,
            mode: mode,
            onSelected: (value) => _setLocale(ref, value),
          ),
        ],
      ),
    };
  }

  Future<void> _setLocale(WidgetRef ref, Locale locale) {
    return ref.read(localeControllerProvider.notifier).setLocale(locale);
  }

  static Locale _supportedLocale(Locale locale) {
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode == locale.languageCode) {
        return supported;
      }
    }
    return const Locale('en');
  }
}

class _LanguageMenuButton extends StatelessWidget {
  const _LanguageMenuButton({
    required this.selectedLocale,
    required this.mode,
    required this.onSelected,
    super.key,
  });

  final Locale selectedLocale;
  final LanguageSwitcherMode mode;
  final ValueChanged<Locale> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppAnchoredPopoverSelector<Locale>(
      value: selectedLocale,
      tooltip: context.l10n.languageSwitcherLabel,
      options: AppLocalizations.supportedLocales
          .map(
            (locale) => AppAnchoredPopoverOption(
              value: locale,
              label: _languageLabel(context, locale),
              key: ValueKey('language-option-${locale.languageCode}'),
            ),
          )
          .toList(),
      onSelected: onSelected,
      matchTriggerWidth: false,
      minPanelWidth: 148,
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
              onTap: togglePopover,
              behavior: HitTestBehavior.opaque,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: mode == LanguageSwitcherMode.compact
                      ? AppColors.glassSurfaceLight
                      : AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: mode == LanguageSwitcherMode.compact
                        ? AppSpacing.sm + 2
                        : AppSpacing.md,
                    vertical: AppSpacing.xs + 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (mode == LanguageSwitcherMode.compact) ...[
                        const Icon(
                          Icons.language_outlined,
                          color: AppColors.textTertiary,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Text(
                        _languageLabel(context, selectedLocale),
                        style: TextStyle(
                          color: mode == LanguageSwitcherMode.compact
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
    );
  }

  String _languageLabel(BuildContext context, Locale locale) {
    final l10n = context.l10n;
    return switch (locale.languageCode) {
      'de' => l10n.languageGerman,
      _ => l10n.languageEnglish,
    };
  }
}
