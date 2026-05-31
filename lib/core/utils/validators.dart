import '../localization/locale_controller.dart';

class FormValidators {
  FormValidators._();

  static String? required(String? value, [String fieldName = 'Field']) {
    final l10n = currentAppLocalizations();
    if (value == null || value.trim().isEmpty) {
      return l10n.validatorFieldRequired(fieldName);
    }
    return null;
  }

  static String? email(String? value) {
    final l10n = currentAppLocalizations();
    if (value == null || value.trim().isEmpty) {
      return l10n.validatorEmailRequired;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return l10n.validatorEmailInvalid;
    }
    return null;
  }

  static String? password(String? value) {
    final l10n = currentAppLocalizations();
    if (value == null || value.isEmpty) {
      return l10n.validatorPasswordRequired;
    }
    if (value.length < 8) {
      return l10n.validatorPasswordMin;
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final l10n = currentAppLocalizations();
    if (value == null || value.isEmpty) {
      return l10n.validatorPasswordConfirmRequired;
    }
    if (value != password) {
      return l10n.validatorPasswordsMismatch;
    }
    return null;
  }

  static String? displayName(String? value) {
    final l10n = currentAppLocalizations();
    if (value == null || value.trim().isEmpty) {
      return l10n.validatorDisplayNameRequired;
    }
    if (value.trim().length < 2) {
      return l10n.validatorDisplayNameMin;
    }
    if (value.trim().length > 30) {
      return l10n.validatorDisplayNameMax;
    }
    return null;
  }
}
