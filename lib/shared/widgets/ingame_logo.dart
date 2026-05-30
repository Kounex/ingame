import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';

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

  double get _iconSize => switch (size) {
        InGameLogoSize.small => 16,
        InGameLogoSize.medium => 18,
        InGameLogoSize.large => 28,
      };

  double get _fontSize => switch (size) {
        InGameLogoSize.small => 16,
        InGameLogoSize.medium => 20,
        InGameLogoSize.large => 42,
      };

  double get _borderRadius => switch (size) {
        InGameLogoSize.small => 6,
        InGameLogoSize.medium => 8,
        InGameLogoSize.large => 12,
      };

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _iconContainerSize,
          height: _iconContainerSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          child: Icon(
            Icons.sports_esports,
            color: Colors.white,
            size: _iconSize,
          ),
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
        const Text(
          'Find your squad. Game together.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
