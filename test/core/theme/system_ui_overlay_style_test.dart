import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/theme/app_theme.dart';

void main() {
  test('dark system UI overlay requests a light status bar', () {
    const overlayStyle = AppTheme.darkSystemUiOverlayStyle;

    expect(overlayStyle.statusBarColor, Colors.transparent);
    expect(overlayStyle.statusBarIconBrightness, Brightness.light);
    expect(overlayStyle.statusBarBrightness, Brightness.dark);
  });
}
