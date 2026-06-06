import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum AppConfirmationVariant { normal, destructive }

Future<bool> showAppConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool useRootNavigator = true,
  AppConfirmationVariant variant = AppConfirmationVariant.normal,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    useRootNavigator: useRootNavigator,
    builder: (dialogContext) => AlertDialog(
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      content: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: variant == AppConfirmationVariant.destructive
                  ? AppColors.error
                  : AppColors.primary,
            ),
          ),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
