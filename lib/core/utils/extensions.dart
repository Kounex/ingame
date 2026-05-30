import 'package:flutter/material.dart';

import '../../shared/widgets/app_toast.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => mediaQuery.size.width;
  double get screenHeight => mediaQuery.size.height;
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;

  void showSnackBar(String message, {bool isError = false}) {
    if (isError) {
      AppToast.error(this, message);
      return;
    }
    AppToast.info(this, message);
  }

  void showSuccessToast(String message) {
    AppToast.success(this, message);
  }

  void showErrorToast(String message) {
    AppToast.error(this, message);
  }

  void showInfoToast(String message) {
    AppToast.info(this, message);
  }

  void showWarningToast(String message) {
    AppToast.warning(this, message);
  }
}

extension StringX on String {
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  String get initials {
    final parts = trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
