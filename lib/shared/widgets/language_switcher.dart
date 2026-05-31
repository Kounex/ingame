import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';
import '../../core/utils/extensions.dart';
import '../../l10n/app_localizations.dart';

enum LanguageSwitcherMode { compact, settingsRow }

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({
    required this.mode,
    super.key,
  });

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
    final popupTheme = Theme.of(context);

    return Theme(
      data: popupTheme.copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        focusColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      ),
      child: PopupMenuButton<Locale>(
        tooltip: context.l10n.languageSwitcherLabel,
        offset: const Offset(0, 8),
        onSelected: onSelected,
        itemBuilder: (context) {
          return AppLocalizations.supportedLocales.map((locale) {
            final isSelected = locale.languageCode == selectedLocale.languageCode;
            return PopupMenuItem<Locale>(
              key: ValueKey('language-option-${locale.languageCode}'),
              value: locale,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: _LanguageMenuItem(
                label: _languageLabel(context, locale),
                selected: isSelected,
              ),
            );
          }).toList();
        },
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

class _LanguageMenuItem extends StatelessWidget {
  const _LanguageMenuItem({
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
            const Icon(
              Icons.check_rounded,
              color: AppColors.primary,
              size: 18,
            ),
        ],
      ),
    );
  }
}
