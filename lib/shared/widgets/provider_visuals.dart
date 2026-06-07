import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

import '../../core/theme/app_theme.dart';

class ProviderVisualSpec {
  const ProviderVisualSpec({
    required this.icon,
    required this.brandColor,
    required this.authBackgroundStart,
    required this.authBackgroundEnd,
    required this.authForegroundColor,
    required this.authIconColor,
    required this.authBorderColor,
    this.authIconBadgeColor,
    this.authShadowColor,
    this.rowConnectedIconColor,
    this.rowDisconnectedIconColor,
    this.rowConnectedBackgroundColor,
    this.rowDisconnectedBackgroundColor,
  });

  final IconData icon;
  final Color brandColor;
  final Color authBackgroundStart;
  final Color authBackgroundEnd;
  final Color authForegroundColor;
  final Color authIconColor;
  final Color authBorderColor;
  final Color? authIconBadgeColor;
  final Color? authShadowColor;
  final Color? rowConnectedIconColor;
  final Color? rowDisconnectedIconColor;
  final Color? rowConnectedBackgroundColor;
  final Color? rowDisconnectedBackgroundColor;
}

class ProviderVisuals {
  ProviderVisuals._();

  static const Color steamBlue = Color(0xFF66C0F4);
  static const Color steamMid = Color(0xFF2A475E);
  static const Color steamNavy = Color(0xFF1B2838);

  static const Color discordPrimary = Color(0xFF5865F2);
  static const Color discordSecondary = Color(0xFF404EED);

  static const Color xboxGreen = Color(0xFF107C10);
  static const Color playStationBlue = Color(0xFF006FCD);
  static const Color nintendoRed = Color(0xFFE60012);
  static const Color appleBlack = Color(0xFF111111);

  static const ProviderVisualSpec email = ProviderVisualSpec(
    icon: LineIcons.envelopeAlt,
    brandColor: AppColors.textTertiary,
    authBackgroundStart: AppColors.backgroundLight,
    authBackgroundEnd: AppColors.backgroundLight,
    authForegroundColor: AppColors.textPrimary,
    authIconColor: AppColors.textTertiary,
    authBorderColor: AppColors.glassBorder,
  );

  static const ProviderVisualSpec unsupported = ProviderVisualSpec(
    icon: LineIcons.questionCircle,
    brandColor: AppColors.warning,
    authBackgroundStart: AppColors.backgroundLight,
    authBackgroundEnd: AppColors.backgroundLight,
    authForegroundColor: AppColors.textPrimary,
    authIconColor: AppColors.warning,
    authBorderColor: AppColors.glassBorder,
  );

  static const ProviderVisualSpec steam = ProviderVisualSpec(
    icon: LineIcons.steam,
    brandColor: steamBlue,
    authBackgroundStart: steamMid,
    authBackgroundEnd: steamNavy,
    authForegroundColor: Color(0xFFE1E8ED),
    authIconColor: steamBlue,
    authBorderColor: steamBlue,
    authIconBadgeColor: Color(0x334FC3F7),
    authShadowColor: Color(0x4066C0F4),
  );

  static const ProviderVisualSpec discord = ProviderVisualSpec(
    icon: LineIcons.discord,
    brandColor: discordPrimary,
    authBackgroundStart: discordPrimary,
    authBackgroundEnd: discordSecondary,
    authForegroundColor: Colors.white,
    authIconColor: Colors.white,
    authBorderColor: Color(0x47FFFFFF),
  );

  static const ProviderVisualSpec apple = ProviderVisualSpec(
    icon: LineIcons.apple,
    brandColor: appleBlack,
    authBackgroundStart: Color(0xFFF5F5F7),
    authBackgroundEnd: Colors.white,
    authForegroundColor: Colors.black,
    authIconColor: Colors.black,
    authBorderColor: Color(0xE6FFFFFF),
    authShadowColor: Color(0x2EFFFFFF),
    rowConnectedIconColor: Colors.white,
    rowDisconnectedIconColor: Color(0xB8FFFFFF),
    rowConnectedBackgroundColor: Color(0x24FFFFFF),
    rowDisconnectedBackgroundColor: AppColors.glassSurfaceLight,
  );

  static const ProviderVisualSpec xbox = ProviderVisualSpec(
    icon: LineIcons.xbox,
    brandColor: xboxGreen,
    authBackgroundStart: xboxGreen,
    authBackgroundEnd: xboxGreen,
    authForegroundColor: Colors.white,
    authIconColor: Colors.white,
    authBorderColor: xboxGreen,
  );

  static const ProviderVisualSpec playstation = ProviderVisualSpec(
    icon: LineIcons.playstation,
    brandColor: playStationBlue,
    authBackgroundStart: playStationBlue,
    authBackgroundEnd: playStationBlue,
    authForegroundColor: Colors.white,
    authIconColor: Colors.white,
    authBorderColor: playStationBlue,
  );

  static const ProviderVisualSpec nintendo = ProviderVisualSpec(
    icon: LineIcons.gamepad,
    brandColor: nintendoRed,
    authBackgroundStart: nintendoRed,
    authBackgroundEnd: nintendoRed,
    authForegroundColor: Colors.white,
    authIconColor: Colors.white,
    authBorderColor: nintendoRed,
  );

  static ProviderVisualSpec forProvider(String provider) {
    return switch (provider) {
      'steam' => steam,
      'discord' => discord,
      'apple' => apple,
      'xbox' => xbox,
      'playstation' => playstation,
      'nintendo' => nintendo,
      'email' => email,
      _ => unsupported,
    };
  }

  static Color rowIconColor(String provider, {required bool connected}) {
    final spec = forProvider(provider);
    if (connected && spec.rowConnectedIconColor != null) {
      return spec.rowConnectedIconColor!;
    }
    if (!connected && spec.rowDisconnectedIconColor != null) {
      return spec.rowDisconnectedIconColor!;
    }
    return connected
        ? spec.brandColor
        : spec.brandColor.withValues(alpha: 0.72);
  }

  static Color rowIconBackground(String provider, {required bool connected}) {
    final spec = forProvider(provider);
    if (connected && spec.rowConnectedBackgroundColor != null) {
      return spec.rowConnectedBackgroundColor!;
    }
    if (!connected && spec.rowDisconnectedBackgroundColor != null) {
      return spec.rowDisconnectedBackgroundColor!;
    }
    if (!connected) return AppColors.glassSurfaceLight;
    return spec.brandColor.withValues(alpha: 0.14);
  }
}
