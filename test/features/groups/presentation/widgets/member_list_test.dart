import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/features/groups/domain/membership_model.dart';
import 'package:ingame/features/groups/presentation/widgets/member_list.dart';
import 'package:ingame/l10n/app_localizations.dart';
import 'package:ingame/shared/providers/presence_provider.dart';
import 'package:ingame/shared/widgets/status_indicator.dart';

void main() {
  testWidgets('member list renders live ready status from provider', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupMemberStatusProvider.overrideWith(
            (ref, key) => UserStatus.ready,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: MemberList(
              groupId: 'group-1',
              members: [
                GroupMember(
                  id: 'membership-1',
                  userId: 'user-1',
                  displayName: 'Alice',
                  role: 'member',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Ready to play'), findsOneWidget);
  });
}
