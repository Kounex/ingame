import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ingame/core/localization/locale_controller.dart';
import 'package:ingame/core/storage/preferences.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/screens/login_screen.dart';
import 'package:ingame/features/profile/presentation/providers/profile_provider.dart';
import 'package:ingame/features/profile/presentation/screens/profile_screen.dart';
import 'package:ingame/l10n/app_localizations.dart';

class _FakeProfileNotifier extends ProfileNotifier {
  _FakeProfileNotifier(this.user);

  final User user;

  @override
  Future<User?> build() async => user;
}

class _LocaleHarness extends ConsumerWidget {
  const _LocaleHarness({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final resolvedLocale = ref.watch(resolvedLocaleProvider);
    intl.Intl.defaultLocale = resolvedLocale.toLanguageTag();

    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );
  }
}

User _profileUser() => const User(
  id: 'user-1',
  displayName: 'Ready Player',
  bio: 'InGame player',
  timezone: 'UTC',
  preferredGamingHours: {
    'monday': [
      {'start': '18:00', 'end': '22:00'},
    ],
  },
);

void main() {
  testWidgets('login language switcher updates copy and persists locale', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(PreferencesService(prefs)),
        ],
        child: const _LocaleHarness(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('language-switcher-compact-trigger')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch').last);
    await tester.pumpAndSettle();

    expect(find.text('E-Mail'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);
    expect(prefs.getString('locale_code'), 'de');
  });

  testWidgets('language switcher menu marks the active language', (tester) async {
    SharedPreferences.setMockInitialValues({'locale_code': 'de'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(PreferencesService(prefs)),
        ],
        child: const _LocaleHarness(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('language-switcher-compact-trigger')),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byKey(const ValueKey('language-option-de')), findsOneWidget);
  });

  testWidgets('profile language switcher reflects and updates shared locale', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'locale_code': 'de'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(PreferencesService(prefs)),
          profileNotifierProvider.overrideWith(
            () => _FakeProfileNotifier(_profileUser()),
          ),
        ],
        child: const _LocaleHarness(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Sprache'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('language-switcher-settings-trigger')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('language-switcher-settings-trigger')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(prefs.getString('locale_code'), 'en');
  });
}
