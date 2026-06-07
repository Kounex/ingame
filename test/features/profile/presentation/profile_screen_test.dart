import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:ingame/core/localization/locale_controller.dart';
import 'package:ingame/core/storage/preferences.dart';
import 'package:ingame/core/theme/glass_components.dart';
import 'package:ingame/features/auth/data/oauth_launcher.dart';
import 'package:ingame/shared/widgets/provider_visuals.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/provider_identity_model.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/features/profile/data/profile_repository.dart';
import 'package:ingame/features/profile/presentation/screens/profile_screen.dart';
import 'package:ingame/l10n/app_localizations.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;
  int logoutCalls = 0;

  @override
  Future<AuthState> build() async => _initialState;

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository(this._user) : super(dio: Dio());

  User _user;
  int unlinkSteamCalls = 0;
  int updateProfileCalls = 0;
  int setEmailPasswordCalls = 0;
  Map<String, dynamic>? lastProfileUpdates;
  String? lastSetEmailPasswordEmail;
  String? lastSetEmailPasswordPassword;

  @override
  Future<User> getProfile() async => _user;

  @override
  Future<User> updateProfile(Map<String, dynamic> updates) async {
    updateProfileCalls++;
    lastProfileUpdates = updates;
    _user = _user.copyWith(
      email: updates['email'] as String? ?? _user.email,
      displayName: updates['display_name'] as String? ?? _user.displayName,
      bio: updates['bio'] as String? ?? _user.bio,
      timezone: updates['timezone'] as String? ?? _user.timezone,
      avatarUrl: updates.containsKey('avatar_url')
          ? updates['avatar_url'] as String?
          : _user.avatarUrl,
      preferredGamingHours:
          updates['preferred_gaming_hours'] as Map<String, dynamic>? ??
          _user.preferredGamingHours,
    );
    return _user;
  }

  @override
  Future<User> setEmailPassword({
    required String email,
    required String password,
  }) async {
    setEmailPasswordCalls++;
    lastSetEmailPasswordEmail = email;
    lastSetEmailPasswordPassword = password;
    _user = _user.copyWith(email: email, hasPasswordLogin: true);
    return _user;
  }

  @override
  Future<User> unlinkSteam() async {
    unlinkSteamCalls++;
    _user = _user.copyWith(steamId: null);
    return _user;
  }
}

class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  String? lastLaunchedUrl;
  int launchCalls = 0;
  bool launchResult = true;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launchCalls++;
    lastLaunchedUrl = url;
    return launchResult;
  }
}

class _ProfileHarness extends ConsumerWidget {
  const _ProfileHarness({required this.home, required this.locale});

  final Widget home;
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeControllerProvider);

    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );
  }
}

Finder _accountRow(String label) {
  return find
      .ancestor(of: find.text(label), matching: find.byType(InkWell))
      .first;
}

Finder _accountInfoRow(String label) {
  return find
      .ancestor(of: find.text(label), matching: find.byType(GestureDetector))
      .first;
}

Finder _accountRowInSection(String sectionTitle, String label) {
  final sectionCard = find.ancestor(
    of: find.text(sectionTitle),
    matching: find.byType(GlassCard),
  );
  return find.descendant(
    of: sectionCard,
    matching: find.ancestor(
      of: find.text(label),
      matching: find.byType(InkWell),
    ),
  );
}

Icon _rowLeadingIcon(WidgetTester tester, Finder rowFinder) {
  return tester.widget<Icon>(
    find.descendant(of: rowFinder, matching: find.byType(Icon)).first,
  );
}

Finder _dialogTextButton(String label) {
  return find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(TextButton, label),
  );
}

Color _rowLeadingContainerColor(WidgetTester tester, Finder rowFinder) {
  final container = tester.widget<Container>(
    find.descendant(of: rowFinder, matching: find.byType(Container)).first,
  );
  final decoration = container.decoration! as BoxDecoration;
  return decoration.color!;
}

Future<void> _scrollToAccountRow(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    _accountRow(label),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  late UrlLauncherPlatform originalUrlLauncherPlatform;

  setUp(() {
    originalUrlLauncherPlatform = UrlLauncherPlatform.instance;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = originalUrlLauncherPlatform;
  });

  Future<void> pumpProfile(
    WidgetTester tester, {
    required _FakeProfileRepository repository,
    _FakeAuthNotifier? authNotifier,
    Locale locale = const Locale('en'),
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    authNotifier ??= _FakeAuthNotifier(
      const AuthState.authenticated(
        User(id: 'auth-user', displayName: 'Tester', timezone: 'UTC'),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(PreferencesService(prefs)),
          profileRepositoryProvider.overrideWithValue(repository),
          authNotifierProvider.overrideWith(() => authNotifier!),
        ],
        child: _ProfileHarness(home: const ProfileScreen(), locale: locale),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'connected Steam row advertises disconnect and shows destructive dialog copy',
    (tester) async {
      final repository = _FakeProfileRepository(
        const User(
          id: 'user-1',
          displayName: 'Steam User',
          email: 'steam@test.com',
          hasPasswordLogin: true,
          steamId: 'steam-123',
          timezone: 'UTC',
        ),
      );

      await pumpProfile(tester, repository: repository);
      await _scrollToAccountRow(tester, 'Steam');

      expect(find.text('Connected. Tap to disconnect.'), findsOneWidget);

      await tester.tap(_accountRow('Steam'));
      await tester.pumpAndSettle();

      expect(find.text('Disconnect Steam?'), findsOneWidget);
      expect(
        find.text('You won\'t be able to sign in with Steam after this.'),
        findsOneWidget,
      );
      expect(
        find.text('Your current session will stay active on this device.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Steam-connected features will stay unavailable until you relink Steam.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Make sure another sign-in method is already connected before you continue.',
        ),
        findsOneWidget,
      );
      expect(find.text('Disconnect'), findsOneWidget);
    },
  );

  testWidgets('profile keeps the primary action within a reading width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 1200);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeProfileRepository(
      const User(id: 'user-1', displayName: 'Schedule User', timezone: 'UTC'),
    );

    await pumpProfile(tester, repository: repository);

    expect(
      tester.getSize(find.widgetWithText(ElevatedButton, 'Edit Profile')).width,
      lessThanOrEqualTo(912),
    );
  });

  testWidgets('successful Steam unlink shows success feedback', (tester) async {
    final repository = _FakeProfileRepository(
      const User(
        id: 'user-1',
        displayName: 'Steam User',
        email: 'steam@test.com',
        hasPasswordLogin: true,
        steamId: 'steam-123',
        timezone: 'UTC',
      ),
    );

    await pumpProfile(tester, repository: repository);
    await _scrollToAccountRow(tester, 'Steam');

    await tester.tap(_accountRow('Steam'));
    await tester.pumpAndSettle();
    await tester.tap(_dialogTextButton('Disconnect'));
    await tester.pumpAndSettle();

    expect(repository.unlinkSteamCalls, 1);
    expect(find.text('Steam disconnected.'), findsOneWidget);

    final steamRow = _accountRow('Steam');
    expect(
      find.descendant(of: steamRow, matching: find.text('Not connected')),
      findsOneWidget,
    );
    expect(
      _rowLeadingIcon(tester, steamRow).color,
      ProviderVisuals.rowIconColor('steam', connected: false),
    );
    expect(
      _rowLeadingContainerColor(tester, steamRow),
      ProviderVisuals.rowIconBackground('steam', connected: false),
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('account email row opens a dedicated change email dialog', (
    tester,
  ) async {
    final repository = _FakeProfileRepository(
      const User(
        id: 'user-1',
        displayName: 'Social User',
        email: 'social@test.com',
        timezone: 'UTC',
      ),
    );

    await pumpProfile(tester, repository: repository);

    await tester.tap(_accountInfoRow('Email'));
    await tester.pumpAndSettle();

    expect(find.text('Change Email'), findsOneWidget);
    final emailField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(emailField.controller?.text, 'social@test.com');

    await tester.enterText(
      find.byType(TextFormField).first,
      'updated@test.com',
    );
    await tester.tap(_dialogTextButton('Save'));
    await tester.pumpAndSettle();

    expect(repository.updateProfileCalls, 1);
    expect(repository.lastProfileUpdates?['email'], 'updated@test.com');
    expect(find.text('updated@test.com'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'email and password dialog uses the persisted recovery email automatically',
    (tester) async {
      final repository = _FakeProfileRepository(
        const User(
          id: 'user-1',
          displayName: 'Social User',
          email: 'social@test.com',
          timezone: 'UTC',
        ),
      );

      await pumpProfile(tester, repository: repository);
      await _scrollToAccountRow(tester, 'Email & Password');

      await tester.tap(_accountRow('Email & Password'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('social@test.com'),
        ),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsNWidgets(2));

      await tester.enterText(find.byType(TextFormField).first, 'password123');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(_dialogTextButton('Add'));
      await tester.pumpAndSettle();

      expect(repository.setEmailPasswordCalls, 1);
      expect(repository.lastSetEmailPasswordEmail, 'social@test.com');
      expect(repository.lastSetEmailPasswordPassword, 'password123');

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('profile splits connected accounts from socials', (tester) async {
    final repository = _FakeProfileRepository(
      const User(
        id: 'user-1',
        displayName: 'Social User',
        email: 'social@test.com',
        timezone: 'UTC',
        providerIdentities: [
          ProviderIdentity(
            provider: 'steam',
            authMode: 'official_openid',
            externalId: 'steam-123',
            username: 'steam_user',
            displayName: 'Steam Hero',
            profileUrl: 'https://steamcommunity.com/profiles/steam-123',
            supportsLogin: true,
            supportsRefresh: true,
            supportsDirectProfileLink: true,
            supportsManualEntry: false,
            supportsCopyOnlyAction: false,
            isSocialIdentity: true,
          ),
          ProviderIdentity(
            provider: 'discord',
            authMode: 'official_oauth',
            externalId: 'discord-123',
            username: 'discord_user',
            displayName: 'Discord Hero',
            email: 'social@test.com',
            avatarUrl: 'https://cdn.discord.test/avatar.png',
            profileUrl: 'https://discord.com/users/discord-123',
            supportsLogin: true,
            supportsRefresh: true,
            supportsDirectProfileLink: true,
            supportsManualEntry: false,
            supportsCopyOnlyAction: false,
            isSocialIdentity: true,
          ),
          ProviderIdentity(
            provider: 'apple',
            authMode: 'official_oauth',
            externalId: 'apple-123',
            supportsLogin: true,
            supportsRefresh: false,
            supportsDirectProfileLink: false,
            supportsManualEntry: false,
            supportsCopyOnlyAction: false,
            isSocialIdentity: false,
          ),
          ProviderIdentity(
            provider: 'xbox',
            authMode: 'manual_unverified',
            externalId: 'MasterChief117',
            username: 'MasterChief117',
            profileUrl:
                'https://account.xbox.com/en-us/profile?gamertag=MasterChief117',
            supportsLogin: false,
            supportsRefresh: false,
            supportsDirectProfileLink: true,
            supportsManualEntry: true,
            supportsCopyOnlyAction: false,
            isSocialIdentity: true,
          ),
          ProviderIdentity(
            provider: 'playstation',
            authMode: 'manual_unverified',
            profileUrl: 'https://profile.playstation.com/share/test-user',
            username: 'PSNHero',
            supportsLogin: false,
            supportsRefresh: false,
            supportsDirectProfileLink: true,
            supportsManualEntry: true,
            supportsCopyOnlyAction: false,
            isSocialIdentity: true,
          ),
          ProviderIdentity(
            provider: 'nintendo',
            authMode: 'manual_unverified',
            externalId: 'SW-1234-5678-9012',
            displayName: 'Switch Buddy',
            metadata: {'friend_code': 'SW-1234-5678-9012'},
            supportsLogin: false,
            supportsRefresh: false,
            supportsDirectProfileLink: false,
            supportsManualEntry: true,
            supportsCopyOnlyAction: true,
            isSocialIdentity: true,
          ),
        ],
      ),
    );

    await pumpProfile(tester, repository: repository);
    await tester.scrollUntilVisible(
      find.text('SOCIALS'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('CONNECTED ACCOUNTS'), findsOneWidget);
    expect(find.text('SOCIALS'), findsOneWidget);
    expect(find.text('Email & Password'), findsOneWidget);
    expect(find.text('Steam'), findsNWidgets(2));
    expect(find.text('Steam Hero'), findsNWidgets(2));
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Discord'), findsNWidgets(2));
    expect(find.text('Discord Hero'), findsNWidgets(2));
    expect(find.text('Xbox'), findsOneWidget);
    expect(find.text('MasterChief117'), findsOneWidget);
    expect(find.text('PlayStation'), findsOneWidget);
    expect(find.text('PSNHero'), findsOneWidget);
    expect(find.text('Nintendo'), findsOneWidget);
    expect(find.text('Switch Buddy'), findsOneWidget);

    final steamConnectedIcon = _rowLeadingIcon(
      tester,
      _accountRowInSection('CONNECTED ACCOUNTS', 'Steam'),
    );
    expect(steamConnectedIcon.icon, LineIcons.steam);
    expect(steamConnectedIcon.color, const Color(0xFF66C0F4));

    final discordSocialIcon = _rowLeadingIcon(
      tester,
      _accountRowInSection('SOCIALS', 'Discord'),
    );
    expect(discordSocialIcon.icon, LineIcons.discord);
    expect(discordSocialIcon.color, const Color(0xFF5865F2));

    final appleConnectedIcon = _rowLeadingIcon(
      tester,
      _accountRowInSection('CONNECTED ACCOUNTS', 'Apple'),
    );
    expect(appleConnectedIcon.icon, LineIcons.apple);
    expect(appleConnectedIcon.color, Colors.white);
    expect(
      find.descendant(
        of: _accountRowInSection('CONNECTED ACCOUNTS', 'Apple'),
        matching: find.text('Connected. Tap to disconnect.'),
      ),
      findsOneWidget,
    );

    final playStationSocialIcon = _rowLeadingIcon(
      tester,
      _accountRowInSection('SOCIALS', 'PlayStation'),
    );
    expect(playStationSocialIcon.icon, LineIcons.playstation);
    expect(playStationSocialIcon.color, const Color(0xFF006FCD));

    final nintendoSocialIcon = _rowLeadingIcon(
      tester,
      _accountRowInSection('SOCIALS', 'Nintendo'),
    );
    expect(nintendoSocialIcon.icon, LineIcons.gamepad);
    expect(nintendoSocialIcon.color, const Color(0xFFE60012));
  });

  testWidgets(
    'mirrored official socials launch profile links from the socials section',
    (tester) async {
      final repository = _FakeProfileRepository(
        const User(
          id: 'user-1',
          displayName: 'Social User',
          timezone: 'UTC',
          providerIdentities: [
            ProviderIdentity(
              provider: 'steam',
              authMode: 'official_openid',
              externalId: 'steam-123',
              displayName: 'Steam Hero',
              profileUrl: 'https://steamcommunity.com/profiles/steam-123',
              supportsLogin: true,
              supportsRefresh: true,
              supportsDirectProfileLink: true,
              supportsManualEntry: false,
              supportsCopyOnlyAction: false,
              isSocialIdentity: true,
            ),
            ProviderIdentity(
              provider: 'discord',
              authMode: 'official_oauth',
              externalId: 'discord-123',
              displayName: 'Discord Hero',
              profileUrl: 'https://discord.com/users/discord-123',
              supportsLogin: true,
              supportsRefresh: true,
              supportsDirectProfileLink: true,
              supportsManualEntry: false,
              supportsCopyOnlyAction: false,
              isSocialIdentity: true,
            ),
          ],
        ),
      );
      final launcher = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = launcher;

      await pumpProfile(tester, repository: repository);
      await tester.scrollUntilVisible(
        find.text('SOCIALS'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(_accountRowInSection('SOCIALS', 'Steam'));
      await tester.pumpAndSettle();
      expect(
        launcher.lastLaunchedUrl,
        'https://steamcommunity.com/profiles/steam-123',
      );

      await tester.tap(_accountRowInSection('SOCIALS', 'Discord'));
      await tester.pumpAndSettle();
      expect(launcher.lastLaunchedUrl, 'https://discord.com/users/discord-123');
      expect(launcher.launchCalls, 2);
    },
  );

  testWidgets(
    'mirrored official socials stay read-only when no profile link is available',
    (tester) async {
      final repository = _FakeProfileRepository(
        const User(
          id: 'user-1',
          displayName: 'Steam User',
          timezone: 'UTC',
          steamId: 'steam-123',
        ),
      );

      await pumpProfile(tester, repository: repository);
      await tester.scrollUntilVisible(
        find.text('SOCIALS'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final steamSocialRow = _accountRowInSection('SOCIALS', 'Steam');
      expect(
        find.descendant(
          of: steamSocialRow,
          matching: find.byIcon(Icons.chevron_right),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: steamSocialRow,
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'connected Xbox social row opens its generated profile action and keeps edit affordance',
    (tester) async {
      final repository = _FakeProfileRepository(
        const User(
          id: 'user-1',
          displayName: 'Xbox User',
          timezone: 'UTC',
          providerIdentities: [
            ProviderIdentity(
              provider: 'xbox',
              authMode: 'manual_unverified',
              externalId: 'MasterChief117',
              username: 'MasterChief117',
              supportsLogin: false,
              supportsRefresh: false,
              supportsDirectProfileLink: true,
              supportsManualEntry: true,
              supportsCopyOnlyAction: false,
              isSocialIdentity: true,
            ),
          ],
        ),
      );
      final launcher = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = launcher;

      await pumpProfile(tester, repository: repository);
      await tester.scrollUntilVisible(
        find.text('SOCIALS'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final xboxRow = _accountRowInSection('SOCIALS', 'Xbox');
      await tester.tap(xboxRow);
      await tester.pumpAndSettle();

      expect(
        launcher.lastLaunchedUrl,
        'https://account.xbox.com/en-us/profile?gamertag=MasterChief117',
      );
      expect(
        find.descendant(
          of: xboxRow,
          matching: find.byIcon(Icons.edit_outlined),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('connected Nintendo social row copies friend code on tap', (
    tester,
  ) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        if (call.method == 'Clipboard.getData') {
          return <String, Object?>{'text': copiedText};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final repository = _FakeProfileRepository(
      const User(
        id: 'user-1',
        displayName: 'Nintendo User',
        timezone: 'UTC',
        providerIdentities: [
          ProviderIdentity(
            provider: 'nintendo',
            authMode: 'manual_unverified',
            externalId: 'SW-1234-5678-9012',
            displayName: 'Switch Buddy',
            metadata: {'friend_code': 'SW-1234-5678-9012'},
            supportsLogin: false,
            supportsRefresh: false,
            supportsDirectProfileLink: false,
            supportsManualEntry: true,
            supportsCopyOnlyAction: true,
            isSocialIdentity: true,
          ),
        ],
      ),
    );

    await pumpProfile(tester, repository: repository);
    await tester.scrollUntilVisible(
      find.text('SOCIALS'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(_accountRowInSection('SOCIALS', 'Nintendo'));
    await tester.pump();

    expect(copiedText, 'SW-1234-5678-9012');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('gaming hours card collapses the full preset set into all day', (
    tester,
  ) async {
    final repository = _FakeProfileRepository(
      const User(
        id: 'user-1',
        displayName: 'Schedule User',
        timezone: 'UTC',
        preferredGamingHours: {
          'monday': [
            {'start': '06:00', 'end': '12:00'},
            {'start': '12:00', 'end': '18:00'},
            {'start': '18:00', 'end': '00:00'},
            {'start': '00:00', 'end': '06:00'},
          ],
        },
      ),
    );

    await pumpProfile(tester, repository: repository);
    await tester.scrollUntilVisible(
      find.text('GAMING HOURS'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('All day'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
  });

  testWidgets('profile localizes fallback schedule ranges', (tester) async {
    final repository = _FakeProfileRepository(
      const User(
        id: 'user-1',
        displayName: 'Schedule User',
        timezone: 'UTC',
        preferredGamingHours: {
          'monday': [
            {'start': '18:00', 'end': '22:00'},
          ],
        },
      ),
    );

    await pumpProfile(
      tester,
      repository: repository,
      locale: const Locale('de'),
    );
    await tester.scrollUntilVisible(
      find.text('18:00 – 22:00'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('18:00 – 22:00'), findsOneWidget);
    expect(find.text('6 PM – 10 PM'), findsNothing);
  });

  testWidgets(
    'last remaining login method shows explicit guidance instead of disconnect flow',
    (tester) async {
      final repository = _FakeProfileRepository(
        const User(
          id: 'user-1',
          displayName: 'Steam Only',
          steamId: 'steam-123',
          timezone: 'UTC',
        ),
      );

      await pumpProfile(tester, repository: repository);
      await _scrollToAccountRow(tester, 'Steam');

      await tester.tap(_accountRow('Steam'));
      await tester.pumpAndSettle();

      expect(
        find.text('Add another sign-in method before disconnecting this one.'),
        findsOneWidget,
      );
      expect(find.text('Disconnect Steam?'), findsNothing);
      expect(repository.unlinkSteamCalls, 0);

      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('logout requires confirmation before ending the session', (
    tester,
  ) async {
    final repository = _FakeProfileRepository(
      const User(id: 'user-1', displayName: 'Tester', timezone: 'UTC'),
    );
    final authNotifier = _FakeAuthNotifier(
      const AuthState.authenticated(
        User(id: 'auth-user', displayName: 'Tester', timezone: 'UTC'),
      ),
    );

    await pumpProfile(
      tester,
      repository: repository,
      authNotifier: authNotifier,
    );
    await tester.scrollUntilVisible(
      find.text('Logout'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Log out?'), findsOneWidget);
    expect(authNotifier.logoutCalls, 0);

    await tester.tap(_dialogTextButton('Logout'));
    await tester.pumpAndSettle();

    expect(authNotifier.logoutCalls, 1);
  });

  testWidgets(
    'profile hides Apple row on unsupported native platforms',
    (tester) async {
      final repository = _FakeProfileRepository(
        const User(id: 'user-1', displayName: 'Android User', timezone: 'UTC'),
      );

      await pumpProfile(tester, repository: repository);
      await _scrollToAccountRow(tester, 'Steam');

      expect(find.text('Apple'), findsNothing);
      expect(find.text('Steam'), findsOneWidget);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.android,
    }),
  );

  testWidgets(
    'profile shows a disconnected Apple row with Apple-specific icon styling on iOS',
    (tester) async {
      final repository = _FakeProfileRepository(
        const User(id: 'user-1', displayName: 'iPhone User', timezone: 'UTC'),
      );

      await pumpProfile(tester, repository: repository);
      await _scrollToAccountRow(tester, 'Steam');

      expect(find.text('Apple'), findsOneWidget);

      final appleRow = _accountRow('Apple');
      expect(
        _rowLeadingIcon(tester, appleRow).color,
        ProviderVisuals.rowIconColor('apple', connected: false),
      );
      expect(
        _rowLeadingContainerColor(tester, appleRow),
        ProviderVisuals.rowIconBackground('apple', connected: false),
      );
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS}),
  );

  testWidgets(
    'profile connected accounts mirrors Discord availability for disconnected builds',
    (tester) async {
      final repository = _FakeProfileRepository(
        const User(
          id: 'user-1',
          displayName: 'No Discord User',
          timezone: 'UTC',
        ),
      );

      await pumpProfile(tester, repository: repository);
      await _scrollToAccountRow(tester, 'Steam');

      final connectedAccountsCard = find.ancestor(
        of: find.text('CONNECTED ACCOUNTS'),
        matching: find.byType(GlassCard),
      );

      if (OAuthLauncher.discordSignInAvailable) {
        expect(
          find.descendant(
            of: connectedAccountsCard,
            matching: find.text('Discord'),
          ),
          findsOneWidget,
        );
      } else {
        expect(
          find.descendant(
            of: connectedAccountsCard,
            matching: find.text('Discord'),
          ),
          findsNothing,
        );
      }
    },
  );

  testWidgets('profile socials only mirror linked official identities', (
    tester,
  ) async {
    final repository = _FakeProfileRepository(
      const User(
        id: 'user-1',
        displayName: 'Manual Only User',
        timezone: 'UTC',
      ),
    );

    await pumpProfile(tester, repository: repository);
    await _scrollToAccountRow(tester, 'Xbox');

    final socialsCard = find.ancestor(
      of: find.text('SOCIALS'),
      matching: find.byType(GlassCard),
    );

    expect(
      find.descendant(of: socialsCard, matching: find.text('Steam')),
      findsNothing,
    );
    expect(
      find.descendant(of: socialsCard, matching: find.text('Discord')),
      findsNothing,
    );
  });
}
