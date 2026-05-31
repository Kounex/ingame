import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/tappable.dart';
import '../../../../shared/widgets/user_avatar.dart';

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    this.imageUrl,
    required this.displayName,
    this.onTap,
  });

  final String? imageUrl;
  final String displayName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap ??
          () {
            AppToast.info(context, context.l10n.avatarUploadSoon);
          },
      child: Stack(
        children: [
          UserAvatar(
            imageUrl: imageUrl,
            displayName: displayName,
            size: 100,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: AppColors.background,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
