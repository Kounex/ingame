import 'package:flutter/material.dart';

import '../../core/utils/extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';

const ingameLogoAssetPath = 'assets/images/ingame-logo.png';

enum InGameLogoSize { small, medium, large }

class InGameLogo extends StatelessWidget {
  const InGameLogo({
    super.key,
    this.size = InGameLogoSize.medium,
    this.showTagline = false,
  });

  final InGameLogoSize size;
  final bool showTagline;

  double get _iconContainerSize => switch (size) {
        InGameLogoSize.small => 28,
        InGameLogoSize.medium => 32,
        InGameLogoSize.large => 48,
      };

  double get _fontSize => switch (size) {
        InGameLogoSize.small => 16,
        InGameLogoSize.medium => 20,
        InGameLogoSize.large => 42,
      };

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          ingameLogoAssetPath,
          width: _iconContainerSize,
          height: _iconContainerSize,
          fit: BoxFit.cover,
        ),
        SizedBox(width: size == InGameLogoSize.large ? AppSpacing.md : AppSpacing.sm),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ).createShader(bounds),
          child: Text(
            'InGame',
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );

    if (!showTagline) return content;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        content,
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.brandTagline,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
