import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final appThemeFile = File('lib/core/theme/app_theme.dart');

  test('dark theme keeps the custom popup menu styling', () {
    final source = appThemeFile.readAsStringSync();

    expect(source, contains('popupMenuTheme: PopupMenuThemeData('));
    expect(source, contains('color: AppColors.backgroundLight'));
    expect(source, contains('surfaceTintColor: Colors.transparent'));
    expect(source, contains('menuPadding: const EdgeInsets.all(8)'));
    expect(source, contains('borderRadius: BorderRadius.circular(18)'));
  });

  test('dark theme uses ultra subtle hairline dividers', () {
    final source = appThemeFile.readAsStringSync();

    expect(source, contains('static const Color hairlineDivider = Color(0x14D6DCE6);'));
    expect(source, contains('dividerColor: AppColors.hairlineDivider'));
    expect(source, contains('dividerTheme: const DividerThemeData('));
    expect(source, contains('color: AppColors.hairlineDivider'));
    expect(source, contains('thickness: 0'));
  });

  test('dark theme gives dialogs the shared glass shell styling', () {
    final source = appThemeFile.readAsStringSync();

    expect(source, contains('dialogTheme: DialogThemeData('));
    expect(source, contains('backgroundColor: AppColors.backgroundLight'));
    expect(source, contains('surfaceTintColor: Colors.transparent'));
    expect(source, contains('borderRadius: BorderRadius.circular(24)'));
    expect(source, contains('side: const BorderSide(color: AppColors.glassBorder)'));
  });

  test('dark theme gives date and time pickers the same glass shell', () {
    final source = appThemeFile.readAsStringSync();

    expect(source, contains('datePickerTheme: DatePickerThemeData('));
    expect(source, contains('timePickerTheme: TimePickerThemeData('));
    expect(source, contains('headerBackgroundColor: Colors.transparent'));
    expect(source, contains('hourMinuteShape: RoundedRectangleBorder('));
    expect(source, contains('dayPeriodShape: RoundedRectangleBorder('));
    expect(source, contains('dialBackgroundColor: AppColors.glassSurface'));
    expect(source, contains('todayForegroundColor: WidgetStateProperty.resolveWith((states) {'));
    expect(source, contains('todayBackgroundColor: WidgetStateProperty.resolveWith((states) {'));
    expect(source, contains('todayBorder: const BorderSide(color: AppColors.primary)'));
  });
}
