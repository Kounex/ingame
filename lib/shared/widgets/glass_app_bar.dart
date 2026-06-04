import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';
import 'desktop_content_region.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.contentWidth = DesktopContentWidth.full,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final DesktopContentWidth contentWidth;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppColors.glassBlurRadius,
          sigmaY: AppColors.glassBlurRadius,
        ),
        child: ColoredBox(
          color: AppColors.glassSurface,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: kToolbarHeight,
              child: DesktopContentRegion(
                width: contentWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: NavigationToolbar(
                    leading: leading,
                    middle: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: actions == null
                        ? null
                        : Row(mainAxisSize: MainAxisSize.min, children: actions!),
                    centerMiddle: centerTitle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
