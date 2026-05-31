import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/networking/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_toast.dart';

class InviteLinkShare extends StatelessWidget {
  const InviteLinkShare({super.key, required this.inviteCode});

  final String inviteCode;

  String get _inviteLink {
    final baseUrl = kIsWeb ? Uri.base.origin : ApiEndpoints.appBaseUrl;
    return '$baseUrl/join/$inviteCode';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.inviteCodeTitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.glassSurfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              inviteCode,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  onPressed: () => _copyLink(context),
                  variant: GlassButtonVariant.secondary,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.copy, size: 16),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.inviteCopyLink),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GlassButton(
                  onPressed: () => _share(context),
                  variant: GlassButtonVariant.ghost,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.share, size: 16),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.commonShare),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _inviteLink));
    AppToast.success(context, context.l10n.inviteLinkCopied);
  }

  void _share(BuildContext context) {
    Clipboard.setData(
      ClipboardData(text: context.l10n.inviteShareText(_inviteLink, inviteCode)),
    );
    AppToast.success(context, context.l10n.inviteDetailsCopied);
  }
}
