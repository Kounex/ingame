import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/profile/presentation/providers/profile_provider.dart';
import 'package:ingame/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:ingame/l10n/app_localizations.dart';

class _RecordingProfileNotifier extends ProfileNotifier {
  _RecordingProfileNotifier(this._user);

  final User _user;
  Map<String, dynamic>? lastUpdates;
  int updateCalls = 0;

  @override
  Future<User?> build() async => _user;

  @override
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    updateCalls++;
    lastUpdates = updates;
    state = AsyncValue.data(
      _user.copyWith(
        preferredGamingHours:
            updates['preferred_gaming_hours'] as Map<String, dynamic>?,
      ),
    );
  }
}

class _DelayedProfileNotifier extends ProfileNotifier {
  _DelayedProfileNotifier(this._profileCompleter);

  final Completer<User?> _profileCompleter;
  Map<String, dynamic>? lastUpdates;
  int updateCalls = 0;

  @override
  Future<User?> build() => _profileCompleter.future;

  @override
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    updateCalls++;
    lastUpdates = updates;
  }
}

void main() {
  Future<void> pumpEditProfile(
    WidgetTester tester, {
    required ProfileNotifier profileNotifier,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, state) => const Scaffold(body: Text('home')),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, state) => const EditProfileScreen(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith(() => profileNotifier),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    await tester.pump();
    router.push('/edit');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('profile edit saves per-day preset slots', (tester) async {
    final profileNotifier = _RecordingProfileNotifier(
      const User(
        id: 'user-1',
        displayName: 'Ready Player',
        bio: 'Evening co-op player',
        timezone: 'UTC',
      ),
    );

    await pumpEditProfile(tester, profileNotifier: profileNotifier);
    await tester.enterText(find.byType(TextFormField).first, 'Ready Player');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('weekly-availability-chip-monday-morning')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('weekly-availability-chip-monday-morning')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('weekly-availability-chip-monday-evening')),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Save Changes'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(profileNotifier.updateCalls, 1);
    expect(profileNotifier.lastUpdates?['preferred_gaming_hours'], {
      'monday': [
        {'start': '06:00', 'end': '12:00'},
        {'start': '18:00', 'end': '00:00'},
      ],
    });
  });

  testWidgets('profile edit waits for profile hydration before showing save', (
    tester,
  ) async {
    final completer = Completer<User?>();
    final profileNotifier = _DelayedProfileNotifier(completer);

    await pumpEditProfile(tester, profileNotifier: profileNotifier);

    expect(
      find.byKey(const Key('edit-profile-loading-indicator')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('edit-profile-save-button')), findsNothing);

    completer.complete(
      const User(
        id: 'user-2',
        displayName: 'Late Loader',
        bio: 'Loaded after route entry',
        timezone: 'Europe/Berlin',
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit-profile-save-button')), findsOneWidget);
    expect(find.text('Late Loader'), findsWidgets);
    expect(find.text('Loaded after route entry'), findsOneWidget);
  });
}
