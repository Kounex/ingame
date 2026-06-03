import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/features/groups/presentation/widgets/invite_link_share.dart';

void main() {
  test('native invite links use invite base URL instead of web app host', () {
    expect(
      InviteLinkShare.inviteLinkForPlatform(
        isWeb: false,
        inviteCode: 'ABC123',
        inviteBaseUrl: 'https://in-game.app',
      ),
      'https://in-game.app/join/ABC123',
    );
  });
}
