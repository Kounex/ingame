import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ingame/app.dart';
import 'package:ingame/core/storage/preferences.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/screens/login_screen.dart';
import 'package:ingame/features/groups/data/groups_repository.dart';
import 'package:ingame/features/groups/domain/group_model.dart';
import 'package:ingame/features/groups/presentation/providers/groups_provider.dart';
import 'package:ingame/features/groups/presentation/screens/group_directory_screen.dart';
import 'package:ingame/features/groups/presentation/screens/groups_list_screen.dart';
import 'package:ingame/features/groups/domain/membership_model.dart';
import 'package:ingame/features/groups/presentation/widgets/invite_link_share.dart';
import 'package:ingame/features/groups/presentation/widgets/member_list.dart';
import 'package:ingame/shared/providers/presence_provider.dart';
import 'package:ingame/shared/widgets/status_indicator.dart';
import 'package:ingame/features/profile/presentation/providers/profile_provider.dart';
import 'package:ingame/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:ingame/l10n/app_localizations.dart';

void main() {
  testWidgets('InGameApp supports English and German locales', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(PreferencesService(prefs)),
        ],
        child: const InGameApp(),
      ),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.supportedLocales, contains(const Locale('en')));
    expect(app.supportedLocales, contains(const Locale('de')));
    expect(app.localizationsDelegates, isNotNull);
    expect(app.locale, isNull);
  });

  testWidgets('login screen renders German localized copy', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(PreferencesService(prefs)),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('E-Mail'), findsOneWidget);
    expect(find.text('Passwort'), findsOneWidget);
    expect(find.text('Anmelden'), findsOneWidget);
    expect(find.text('Noch kein Konto?'), findsOneWidget);
    expect(find.text('Registrieren'), findsOneWidget);
    expect(find.text('oder'), findsOneWidget);
    expect(find.text('Mit Steam fortfahren'), findsOneWidget);
  });

  testWidgets('German app surfaces expose localized profile and groups copy',
      (tester) async {
    Future<void> pumpGermanHome(Widget home) async {
      final container = ProviderContainer(
        overrides: [
          groupsRepositoryProvider.overrideWithValue(_FakeGroupsRepository()),
          groupsNotifierProvider.overrideWith(
            () => _EmptyGroupsNotifier(),
          ),
          profileNotifierProvider.overrideWith(
            () => _FakeProfileNotifier(_profileUser()),
          ),
        ],
      );
      await container.read(profileNotifierProvider.future);
      await container.read(groupsNotifierProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('de'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: home,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpGermanHome(const GroupDirectoryScreen());

    expect(find.text('Gruppen entdecken'), findsOneWidget);
    expect(find.text('Gruppen suchen...'), findsOneWidget);
    expect(find.text('Noch keine sichtbaren Gruppen'), findsOneWidget);

    await pumpGermanHome(const EditProfileScreen());

    expect(find.text('Profil bearbeiten'), findsOneWidget);
    expect(find.text('Gaming-Zeiten'), findsOneWidget);
    expect(find.text('Zeitzone'), findsOneWidget);
    expect(find.text('Änderungen speichern'), findsOneWidget);

    await pumpGermanHome(const GroupsListScreen());

    expect(find.text('Meine Gruppen'), findsOneWidget);
    expect(find.text('Noch keine Gruppen'), findsOneWidget);
    expect(find.text('Gruppe erstellen'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(
          body: InviteLinkShare(inviteCode: 'ABC123'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Einladungscode'), findsOneWidget);
    expect(find.text('Link kopieren'), findsOneWidget);
    expect(find.text('Teilen'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupMemberStatusProvider.overrideWith(
            (ref, key) => UserStatus.ready,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: MemberList(
              groupId: 'group-1',
              members: const [
                GroupMember(
                  id: 'membership-1',
                  userId: 'user-1',
                  displayName: 'Alice',
                  role: 'owner',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Besitzer'), findsOneWidget);
    expect(find.text('Spielbereit'), findsOneWidget);
  });
}

class _FakeGroupsRepository extends GroupsRepository {
  _FakeGroupsRepository() : super(dio: Dio());

  @override
  Future<List<Group>> discoverGroups({String? search}) async => [];
}

class _EmptyGroupsNotifier extends GroupsNotifier {
  @override
  Future<List<Group>> build() async => [];

  @override
  Future<void> load() async {
    state = const AsyncValue.data([]);
  }
}

class _FakeProfileNotifier extends ProfileNotifier {
  _FakeProfileNotifier(this.user);

  final User user;

  @override
  Future<User?> build() async => user;
}

User _profileUser() => const User(
      id: 'user-1',
      displayName: 'Ready Player',
      bio: 'InGame-Spieler',
      timezone: 'Europe/Berlin',
      preferredGamingHours: {
        'monday': [
          {'start': '18:00', 'end': '22:00'},
        ],
      },
    );
