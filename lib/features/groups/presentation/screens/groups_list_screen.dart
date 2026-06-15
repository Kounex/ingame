import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/networking/api_error.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/desktop_content_region.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../domain/membership_model.dart';
import '../providers/groups_provider.dart';
import '../widgets/group_card.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsNotifierProvider);
    final pendingAsync = ref.watch(myPendingJoinRequestsProvider);

    return AppBackgroundSurface(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: context.l10n.groupsListTitle,
          contentWidth: DesktopContentWidth.reading,
        ),
        body: groupsAsync.when(
          loading: () => const DesktopContentRegion(
            width: DesktopContentWidth.reading,
            child: LoadingIndicator(),
          ),
          error: (error, _) => DesktopContentRegion(
            width: DesktopContentWidth.reading,
            child: ErrorDisplay(
              message: ApiError.userMessage(error, context.l10n),
              onRetry: () => ref.read(groupsNotifierProvider.notifier).load(),
            ),
          ),
          data: (groups) {
            if (groups.isEmpty) {
              return DesktopContentRegion(
                width: DesktopContentWidth.reading,
                child: _EmptyState(
                  onCreateGroup: () => context.goNamed(RouteNames.createGroup),
                  onBrowseGroups: () => context.goNamed(RouteNames.discover),
                ),
              );
            }

            final pendingRequests = pendingAsync.value ?? [];

            return DesktopContentRegion(
              width: DesktopContentWidth.reading,
              child: AppRefreshIndicator(
                onRefresh: () async {
                  await ref.read(groupsNotifierProvider.notifier).load();
                  ref.invalidate(myPendingJoinRequestsProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  children: [
                    if (pendingRequests.isNotEmpty)
                      _PendingRequestsSection(requests: pendingRequests),
                    for (final group in groups) GroupCard(group: group),
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: groupsAsync.value?.isNotEmpty == true
            ? FloatingActionButton(
                onPressed: () => context.goNamed(RouteNames.createGroup),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: AppColors.background),
              )
            : null,
      ),
    );
  }
}

class _PendingRequestsSection extends StatelessWidget {
  const _PendingRequestsSection({required this.requests});

  final List<MyJoinRequest> requests;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              context.l10n.pendingJoinRequestsTitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final request in requests)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.hourglass_top_rounded,
                        size: 18,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.groupName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.pendingJoinRequestWaiting,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onCreateGroup,
    required this.onBrowseGroups,
  });

  final VoidCallback onCreateGroup;
  final VoidCallback onBrowseGroups;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.groupsEmptyTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.groupsEmptySubtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                onPressed: onCreateGroup,
                child: Text(context.l10n.groupsCreate),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                onPressed: onBrowseGroups,
                variant: GlassButtonVariant.secondary,
                child: Text(context.l10n.groupsBrowse),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
