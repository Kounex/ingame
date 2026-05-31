import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('steam web callback uses localStorage fallback instead of native scheme', () async {
    final html = await File('web/auth/steam-callback.html').readAsString();

    expect(
      html,
      contains("localStorage.setItem('flutter-web-auth-2', window.location.href);"),
    );
    expect(html, isNot(contains('window.location.replace(nativeCallbackUrl);')));
  });
}
