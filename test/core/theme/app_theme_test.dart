import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ingame/core/theme/app_theme.dart';

void main() {
  test('dark theme defines a custom popup menu theme', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    final theme = AppTheme.darkTheme;
    final popupTheme = theme.popupMenuTheme;

    expect(popupTheme.color, AppColors.backgroundLight);
    expect(popupTheme.surfaceTintColor, Colors.transparent);
    expect(popupTheme.menuPadding, const EdgeInsets.all(8));

    final shape = popupTheme.shape as RoundedRectangleBorder?;
    expect(shape, isNotNull);
    expect(shape!.borderRadius, BorderRadius.circular(18));
  });
}
