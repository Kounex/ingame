import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/domain/user_model.dart';
import '../../../../shared/utils/social_identity_helpers.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/gaming_hours_display.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/social_identities_card.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../domain/membership_model.dart';
import '../providers/member_profile_provider.dart';

void showMemberProfileSheet(
  BuildContext context, {
  required GroupMember member,
}) {
  showAppBottomSheet(
    context: context,
    builder: (_) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: _MemberProfileSheet(member: member),
    ),
  );
}

class _MemberProfileSheet extends ConsumerWidget {
  const _MemberProfileSheet({required this.member});

  final GroupMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(memberProfileProvider(member.userId));

    return AppBottomSheet(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        padding: AppBottomSheet.defaultPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(
              imageUrl: member.avatarUrl,
              displayName: member.displayName,
              size: 80,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              member.displayName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            profileAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: AppSpacing.lg),
                child: LoadingIndicator(),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  context.l10n.errorSomethingWentWrong,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                  ),
                ),
              ),
              data: (user) => _ProfileContent(user: user),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final socialEntries = buildReadOnlySocialEntries(context, user);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            user.bio!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetSectionHeader(
                title: context.l10n.profileSectionGamingHours,
              ),
              const SizedBox(height: AppSpacing.md),
              GamingHoursDisplay(gamingHours: user.preferredGamingHours),
            ],
          ),
        ),
        if (socialEntries.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SocialIdentitiesCard(
            title: context.l10n.profileSectionSocials,
            entries: socialEntries,
          ),
        ],
      ],
    );
  }
}

class _SheetSectionHeader extends StatelessWidget {
  const _SheetSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: AppColors.textTertiary.withValues(alpha: 0.8),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}
