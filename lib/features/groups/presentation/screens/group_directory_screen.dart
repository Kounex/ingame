import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/networking/api_error.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../data/groups_repository.dart';
import '../../domain/group_model.dart';
import '../providers/groups_provider.dart';

class GroupDirectoryScreen extends ConsumerStatefulWidget {
  const GroupDirectoryScreen({super.key});

  @override
  ConsumerState<GroupDirectoryScreen> createState() =>
      _GroupDirectoryScreenState();
}

class _GroupDirectoryScreenState extends ConsumerState<GroupDirectoryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Group>? _groups;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _loadGroups(search: query.trim().isEmpty ? null : query.trim());
    });
  }

  Future<void> _loadGroups({String? search}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(groupsRepositoryProvider);
      final groups = await repo.discoverGroups(search: search);
      if (mounted) {
        setState(() {
          _groups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _joinGroup(Group group) async {
    try {
      if (group.joinMode == 'open') {
        final repo = ref.read(groupsRepositoryProvider);
        await repo.joinByInviteCode(group.inviteCode);
        await ref.read(groupsNotifierProvider.notifier).load();
        if (mounted) {
          AppToast.success(
            context,
            context.l10n.groupDirectoryJoinSuccess(group.name),
          );
          context.goNamed(
            RouteNames.groupDetail,
            pathParameters: {'id': group.id},
          );
        }
      } else {
        final repo = ref.read(groupsRepositoryProvider);
        await repo.createJoinRequest(group.id);
        if (mounted) {
          AppToast.info(context, context.l10n.groupDirectoryJoinRequestSent);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, ApiError.userMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        appBar: GlassAppBar(title: context.l10n.groupDirectoryTitle),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: GlassInput(
                controller: _searchController,
                hint: context.l10n.groupDirectorySearchHint,
                prefixIcon: Icons.search,
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const LoadingIndicator();

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassButton(
              onPressed: _loadGroups,
              variant: GlassButtonVariant.secondary,
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (_groups == null || _groups!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.explore_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _searchController.text.isNotEmpty
                  ? context.l10n.groupDirectoryNoResults
                  : context.l10n.groupDirectoryNoDiscoverable,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: _groups!.length,
      itemBuilder: (context, index) {
        final group = _groups![index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${group.memberCount}',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (group.description != null &&
                    group.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    group.description!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: GlassButton(
                    onPressed: () => _joinGroup(group),
                    variant: group.joinMode == 'open'
                        ? GlassButtonVariant.primary
                        : GlassButtonVariant.secondary,
                    child: Text(
                      group.joinMode == 'open'
                          ? context.l10n.groupDirectoryJoinAction
                          : context.l10n.groupDirectoryRequestJoinAction,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
