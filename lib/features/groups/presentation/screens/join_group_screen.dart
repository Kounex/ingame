import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/networking/api_error.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../../data/groups_repository.dart';
import '../../domain/group_model.dart';
import '../providers/groups_provider.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key, required this.inviteCode});

  final String inviteCode;

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  Group? _groupPreview;
  bool _isLoadingPreview = true;
  bool _isJoining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreview();
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
        appBar: GlassAppBar(
          title: 'Join Group',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.group_add_outlined,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'You\'ve been invited!',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _groupPreview == null
                          ? 'Tap below to join this group'
                          : 'Join ${_groupPreview!.name}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_isLoadingPreview)
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.md),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (_groupPreview != null) ...[
                      Text(
                        _groupPreview!.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if ((_groupPreview!.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _groupPreview!.description!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _InfoPill(
                            icon: Icons.people_outline,
                            label: '${_groupPreview!.memberCount} members',
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _InfoPill(
                            icon: _groupPreview!.joinMode == 'open'
                                ? Icons.open_in_new
                                : Icons.approval_outlined,
                            label: _groupPreview!.joinMode == 'open'
                                ? 'Open join'
                                : 'Approval required',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.glassSurfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.inviteCode,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  onPressed: _isJoining ? null : _joinGroup,
                  isLoading: _isJoining,
                  child: const Text('Join Group'),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _joinGroup() async {
    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      final repo = ref.read(groupsRepositoryProvider);
      final group = await repo.joinByInviteCode(widget.inviteCode);
      await ref.read(groupsNotifierProvider.notifier).load();

      if (mounted) {
        context.pushReplacementNamed(
          RouteNames.groupDetail,
          pathParameters: {'id': group.id},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _error = ApiError.userMessage(e);
        });
      }
    }
  }

  Future<void> _loadPreview() async {
    try {
      final repo = ref.read(groupsRepositoryProvider);
      final group = await repo.previewByInviteCode(widget.inviteCode);
      if (!mounted) return;
      setState(() {
        _groupPreview = group;
        _isLoadingPreview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiError.userMessage(e);
        _isLoadingPreview = false;
      });
    }
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.glassSurfaceLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
