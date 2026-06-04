import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web shell paints iOS Safari chrome with the app background', () async {
    final indexHtml = await File('web/index.html').readAsString();

    expect(indexHtml, contains('viewport-fit=cover'));
    expect(indexHtml, contains('name="theme-color"'));
    expect(indexHtml, contains('InGame helps friends coordinate gaming sessions'));
    expect(indexHtml, contains('#0A0E1A'));
    expect(indexHtml, contains('background-color: #0A0E1A'));
    expect(indexHtml, contains('margin: 0'));
  });
}
