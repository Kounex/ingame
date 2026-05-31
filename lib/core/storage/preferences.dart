import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const _onboardingCompleteKey = 'onboarding_complete';
  static const _localeCodeKey = 'locale_code';

  bool get isOnboardingComplete =>
      _prefs.getBool(_onboardingCompleteKey) ?? false;

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(_onboardingCompleteKey, value);
  }

  String? get localeCode => _prefs.getString(_localeCodeKey);

  Future<void> setLocaleCode(String? value) async {
    if (value == null || value.isEmpty) {
      await _prefs.remove(_localeCodeKey);
      return;
    }
    await _prefs.setString(_localeCodeKey, value);
  }

  Future<void> clear() async {
    await _prefs.clear();
  }
}

final preferencesProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError(
      'Must be overridden with SharedPreferences instance');
});
