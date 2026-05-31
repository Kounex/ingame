import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../l10n/app_localizations.dart';
import '../storage/preferences.dart';

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final preferences = ref.read(preferencesProvider);
    final localeCode = preferences.localeCode;
    if (localeCode == null || localeCode.isEmpty) {
      return null;
    }
    return Locale(localeCode);
  }

  Future<void> setLocale(Locale? locale) async {
    final preferences = ref.read(preferencesProvider);
    await preferences.setLocaleCode(locale?.languageCode);
    state = locale;
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);

final resolvedLocaleProvider = Provider<Locale>((ref) {
  final locale = ref.watch(localeControllerProvider);
  return locale ?? PlatformDispatcher.instance.locale;
});

final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(resolvedLocaleProvider);
  return lookupAppLocalizations(_supportedLocale(locale));
});

AppLocalizations currentAppLocalizations([Locale? locale]) {
  return lookupAppLocalizations(_supportedLocale(locale ?? _currentIntlLocale()));
}

Locale _currentIntlLocale() {
  final current = intl.Intl.getCurrentLocale();
  if (current.isEmpty) {
    return const Locale('en');
  }

  final normalized = current.replaceAll('-', '_');
  final parts = normalized.split('_');
  return Locale.fromSubtags(
    languageCode: parts.first,
    countryCode: parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null,
  );
}

Locale _supportedLocale(Locale locale) {
  for (final supported in AppLocalizations.supportedLocales) {
    if (supported.languageCode == locale.languageCode) {
      return supported;
    }
  }
  return const Locale('en');
}
