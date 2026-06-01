import 'package:flutter/material.dart';

mixin LocaleAwareFormStateMixin<T extends StatefulWidget> on State<T> {
  Locale? _lastLocale;

  void revalidateFormOnLocaleChange({
    required GlobalKey<FormState> formKey,
    required bool shouldRevalidate,
  }) {
    final locale = Localizations.maybeLocaleOf(context);
    if (locale == null) return;

    if (_lastLocale == null) {
      _lastLocale = locale;
      return;
    }

    if (_lastLocale == locale) {
      return;
    }

    _lastLocale = locale;
    if (!shouldRevalidate) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      formKey.currentState?.validate();
    });
  }
}
