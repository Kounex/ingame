import 'package:flutter/material.dart';

import 'status_indicator.dart';
import 'user_avatar.dart';

class AvatarWithStatus extends StatelessWidget {
  const AvatarWithStatus({
    super.key,
    required this.displayName,
    this.imageUrl,
    this.status = UserStatus.offline,
    this.size = 40,
  });

  final String displayName;
  final String? imageUrl;
  final UserStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final indicatorSize = (size * 0.28).clamp(10.0, 16.0).toDouble();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        UserAvatar(
          imageUrl: imageUrl,
          displayName: displayName,
          size: size,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: StatusIndicator(
            status: status,
            size: indicatorSize,
          ),
        ),
      ],
    );
  }
}
