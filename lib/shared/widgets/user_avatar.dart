import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.imageUrl,
    this.imageBytes,
    required this.displayName,
    this.size = 40,
    this.isOnline,
  });

  final String? imageUrl;
  final Uint8List? imageBytes;
  final String displayName;
  final double size;
  final bool? isOnline;

  Widget _fallbackAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.glassSurfaceLight,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        displayName.initials,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: size * 0.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = _fallbackAvatar();

    if (imageBytes != null) {
      avatar = ClipOval(
        child: Image.memory(
          imageBytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackAvatar(),
        ),
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackAvatar(),
        ),
      );
    }

    return Stack(
      children: [
        avatar,
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
                border: Border.all(color: AppColors.background, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
