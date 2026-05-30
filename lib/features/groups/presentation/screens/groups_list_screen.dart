import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../providers/groups_provider.dart';
import '../widgets/group_card.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsNotifierProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.background, AppColors.backgroundLight],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const GlassAppBar(title: 'My Groups'),
        body: groupsAsync.when(
          loading: () => const LoadingIndicator(),
          error: (error, _) => ErrorDisplay(
            message: error.toString(),
            onRetry: () => ref.read(groupsNotifierProvider.notifier).load(),
          ),
          data: (groups) {
            if (groups.isEmpty) {
              return _EmptyState(
                onCreateGroup: () =>
                    context.goNamed(RouteNames.createGroup),
                onBrowseGroups: () =>
                    context.goNamed(RouteNames.discover),
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.backgroundLight,
              onRefresh: () =>
                  ref.read(groupsNotifierProvider.notifier).load(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                itemCount: groups.length,
                itemBuilder: (context, index) =>
                    GroupCard(group: groups[index]),
              ),
            );
          },
        ),
        floatingActionButton: groupsAsync.valueOrNull?.isNotEmpty == true
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
            const Text(
              'No groups yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Create or join your first group',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                onPressed: onCreateGroup,
                child: const Text('Create Group'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                onPressed: onBrowseGroups,
                variant: GlassButtonVariant.secondary,
                child: const Text('Browse Groups'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
