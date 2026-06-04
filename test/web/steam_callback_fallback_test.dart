import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('steam callback keeps web fallback and native app bridge', () async {
    final html = await File('web/auth/steam-callback.html').readAsString();

    expect(
      html,
      contains(
        "localStorage.setItem('flutter-web-auth-2', window.location.href);",
      ),
    );
    expect(html, contains('window.location.replace(nativeCallbackUrl);'));
    expect(html, contains('ingame://auth/steam/callback'));
    expect(html, contains('ingame_native'));
  });
}
