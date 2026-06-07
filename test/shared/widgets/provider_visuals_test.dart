import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:line_icons/line_icons.dart';

import 'package:ingame/core/theme/app_theme.dart';
import 'package:ingame/shared/widgets/provider_visuals.dart';

void main() {
  test('provider visuals expose branded mappings for supported providers', () {
    expect(ProviderVisuals.forProvider('steam').icon, LineIcons.steam);
    expect(ProviderVisuals.forProvider('discord').icon, LineIcons.discord);
    expect(ProviderVisuals.forProvider('apple').icon, LineIcons.apple);
    expect(ProviderVisuals.forProvider('xbox').icon, LineIcons.xbox);
    expect(
      ProviderVisuals.forProvider('playstation').icon,
      LineIcons.playstation,
    );
    expect(ProviderVisuals.forProvider('nintendo').icon, LineIcons.gamepad);
  });

  test('provider visuals do not alias unknown providers to email', () {
    final unsupported = ProviderVisuals.forProvider('future-provider');
    final email = ProviderVisuals.forProvider('email');

    expect(unsupported.icon, isNot(email.icon));
    expect(unsupported.brandColor, isNot(email.brandColor));
  });

  test('row icon treatment uses provider tinting instead of success green', () {
    expect(
      ProviderVisuals.rowIconColor('steam', connected: true),
      ProviderVisuals.steamBlue,
    );
    expect(
      ProviderVisuals.rowIconBackground('steam', connected: true),
      ProviderVisuals.steamBlue.withValues(alpha: 0.14),
    );
    expect(
      ProviderVisuals.rowIconBackground('email', connected: false),
      AppColors.glassSurfaceLight,
    );
    expect(
      ProviderVisuals.rowIconColor('apple', connected: true),
      Colors.white,
    );
    expect(
      ProviderVisuals.rowIconBackground('apple', connected: true),
      const Color(0x24FFFFFF),
    );
  });
}
