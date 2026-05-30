import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.displayName,
    this.size = 40,
    this.isOnline,
  });

  final String? imageUrl;
  final String displayName;
  final double size;
  final bool? isOnline;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: AppColors.glassSurfaceLight,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Text(
                  displayName.initials,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        if (isOnline != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: isOnline! ? AppColors.success : AppColors.textTertiary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.background,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
