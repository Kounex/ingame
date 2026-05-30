import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/networking/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/app_toast.dart';

class InviteLinkShare extends StatelessWidget {
  const InviteLinkShare({super.key, required this.inviteCode});

  final String inviteCode;

  String get _inviteLink {
    final baseUrl = kIsWeb ? Uri.base.origin : ApiEndpoints.appBaseUrl;
    return '$baseUrl/join/$inviteCode';
  }

  String get _shareText =>
      'Join my InGame group with this link: $_inviteLink\nInvite code: $inviteCode';

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invite Code',
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy, size: 16),
                      SizedBox(width: AppSpacing.sm),
                      Text('Copy Link'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GlassButton(
                  onPressed: () => _share(context),
                  variant: GlassButtonVariant.ghost,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share, size: 16),
                      SizedBox(width: AppSpacing.sm),
                      Text('Share'),
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
    AppToast.success(context, 'Invite link copied to clipboard');
  }

  void _share(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _shareText));
    AppToast.success(context, 'Invite details copied to clipboard');
  }
}
