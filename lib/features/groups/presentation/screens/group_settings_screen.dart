import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_controller.dart';
import '../../../../core/networking/api_error.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/providers/presence_provider.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/avatar_with_status.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/status_indicator.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../data/groups_repository.dart';
import '../../domain/membership_model.dart';
import '../providers/group_detail_provider.dart';
import '../providers/groups_provider.dart';

class GroupSettingsScreen extends ConsumerStatefulWidget {
  const GroupSettingsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupSettingsScreen> createState() =>
      _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isDiscoverable = false;
  String _joinMode = 'open';
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initFromGroup(GroupDetailState detail) {
    if (!_hasChanges) {
      _nameController.text = detail.group.name;
      _descriptionController.text = detail.group.description ?? '';
      _isDiscoverable = detail.group.isDiscoverable;
      _joinMode = detail.group.joinMode;
    }
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(groupsRepositoryProvider);
      await repo.updateGroup(widget.groupId, {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'is_discoverable': _isDiscoverable,
        'join_mode': _joinMode,
      });
      ref.invalidate(groupDetailNotifierProvider(widget.groupId));
      ref.invalidate(groupsNotifierProvider);
      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasChanges = false;
        });
        AppToast.success(context, context.l10n.groupSettingsUpdated);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.error(context, ApiError.userMessage(e, context.l10n));
      }
    }
  }

  Future<void> _removeMember(String userId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        title: Text(
          context.l10n.groupSettingsRemoveMemberTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          context.l10n.groupSettingsRemoveMemberMessage(displayName),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.l10n.commonRemove,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(groupsRepositoryProvider);
      await repo.removeMember(widget.groupId, userId);
      ref
          .read(groupDetailNotifierProvider(widget.groupId).notifier)
          .refresh();
      if (mounted) {
        AppToast.success(
          context,
          context.l10n.groupSettingsMemberRemoved(displayName),
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, ApiError.userMessage(e, context.l10n));
      }
    }
  }

  Future<void> _approveRequest(String requestId) async {
    try {
      await ref
          .read(groupDetailNotifierProvider(widget.groupId).notifier)
          .resolveRequest(requestId, approved: true);
      if (mounted) {
        AppToast.success(context, context.l10n.groupSettingsRequestApproved);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, ApiError.userMessage(e, context.l10n));
      }
    }
  }

  Future<void> _denyRequest(String requestId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        title: Text(
          context.l10n.groupSettingsDenyRequestTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          context.l10n.groupSettingsDenyRequestMessage(displayName),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.l10n.commonDeny,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(groupDetailNotifierProvider(widget.groupId).notifier)
          .resolveRequest(requestId, approved: false);
      if (mounted) {
        AppToast.info(context, context.l10n.groupSettingsRequestDenied);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, ApiError.userMessage(e, context.l10n));
      }
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        title: Text(
          context.l10n.groupSettingsDeleteTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          context.l10n.groupSettingsDeleteMessage,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.l10n.commonDelete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(groupsNotifierProvider.notifier).delete(widget.groupId);
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, ApiError.userMessage(e, context.l10n));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(groupDetailNotifierProvider(widget.groupId));
    final l10n = context.l10n;

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
          title: l10n.groupSettingsTitle,
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Text(
                        l10n.commonSave,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
          ],
        ),
        body: detailAsync.when(
          loading: () => const Center(child: LoadingIndicator()),
          error: (error, _) => Center(
            child: Text(
              ApiError.userMessage(error, context.l10n),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          data: (detail) {
            _initFromGroup(detail);
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionLabel(l10n.groupSettingsSectionGroupInfo.toUpperCase()),
                  const SizedBox(height: AppSpacing.sm),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        GlassInput(
                          controller: _nameController,
                          label: l10n.createGroupNameLabel,
                          prefixIcon: Icons.group_outlined,
                          onChanged: (_) => _markChanged(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        GlassInput(
                          controller: _descriptionController,
                          label: l10n.createGroupDescriptionLabel,
                          prefixIcon: Icons.notes_outlined,
                          maxLines: 3,
                          onChanged: (_) => _markChanged(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionLabel(l10n.groupSettingsSectionVisibility.toUpperCase()),
                  const SizedBox(height: AppSpacing.sm),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      children: [
                        _SettingsSwitch(
                          icon: Icons.explore_outlined,
                          title: l10n.createGroupDiscoverableTitle,
                          subtitle: l10n.createGroupDiscoverableSubtitle,
                          value: _isDiscoverable,
                          onChanged: (v) {
                            setState(() => _isDiscoverable = v);
                            _markChanged();
                          },
                        ),
                        if (_isDiscoverable) ...[
                          const Divider(
                            color: AppColors.glassBorder,
                            height: 1,
                          ),
                          _SettingsRadio(
                            icon: Icons.door_front_door_outlined,
                            title: l10n.createGroupJoinModeLabel,
                            options: {
                              'open':
                                  '${l10n.groupJoinModeOpenLabel} - ${l10n.groupJoinModeOpenDescription}',
                              'approval':
                                  '${l10n.groupJoinModeApprovalLabel} - ${l10n.groupJoinModeApprovalDescription}',
                            },
                            value: _joinMode,
                            onChanged: (v) {
                              setState(() => _joinMode = v);
                              _markChanged();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionLabel(
                    l10n.groupSettingsSectionMembers(detail.members.length)
                        .toUpperCase(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0;
                            i < detail.members.length;
                            i++) ...[
                          if (i > 0)
                            const Divider(
                              color: AppColors.glassBorder,
                              height: 1,
                            ),
                          _MemberSettingsRow(
                            groupId: widget.groupId,
                            member: detail.members[i],
                            onRemove: detail.members[i].role != 'owner'
                                ? () => _removeMember(
                                      detail.members[i].userId,
                                      detail.members[i].displayName,
                                    )
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (detail.pendingRequests.isNotEmpty) ...[
                    _SectionLabel(
                      l10n
                          .groupSettingsSectionPendingRequests(
                            detail.pendingRequests.length,
                          )
                          .toUpperCase(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        children: [
                          for (var i = 0;
                              i < detail.pendingRequests.length;
                              i++) ...[
                            if (i > 0)
                              const Divider(
                                color: AppColors.glassBorder,
                                height: 1,
                              ),
                            _JoinRequestRow(
                              request: detail.pendingRequests[i],
                              onApprove: () =>
                                  _approveRequest(detail.pendingRequests[i].id),
                              onDeny: () => _denyRequest(
                                detail.pendingRequests[i].id,
                                detail.pendingRequests[i].user.displayName,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  _SectionLabel(l10n.groupSettingsSectionDangerZone.toUpperCase()),
                  const SizedBox(height: AppSpacing.sm),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.groupSettingsDangerDescription,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        GlassButton(
                          onPressed: _deleteGroup,
                          variant: GlassButtonVariant.ghost,
                          child: Text(
                            l10n.groupSettingsDeleteTitle,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textTertiary.withValues(alpha: 0.8),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _SettingsRadio extends StatelessWidget {
  const _SettingsRadio({
    required this.icon,
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final Map<String, String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child:
                Icon(icon, size: 20, color: AppColors.textTertiary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final entry in options.entries)
                  InkWell(
                    onTap: () => onChanged(entry.key),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs + 2),
                      child: Row(
                        children: [
                          Icon(
                            value == entry.key
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: value == entry.key
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                color: value == entry.key
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberSettingsRow extends ConsumerWidget {
  const _MemberSettingsRow({
    required this.groupId,
    required this.member,
    this.onRemove,
  });

  final String groupId;
  final dynamic member;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = member.role as String;
    final isOwner = role.toLowerCase() == 'owner';
    final userId = member.userId as String;
    final displayName = member.displayName as String;
    final avatarUrl = member.avatarUrl as String?;
    final status = ref.watch(
      groupMemberStatusProvider((groupId: groupId, userId: userId)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          AvatarWithStatus(
            imageUrl: avatarUrl,
            displayName: displayName,
            status: status,
            size: 36,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _statusLabel(context, status),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _roleLabel(role),
                  style: TextStyle(
                    color: isOwner
                        ? AppColors.primary
                        : AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: AppColors.error,
                size: 20,
              ),
              onPressed: onRemove,
              tooltip: context.l10n.groupSettingsRemoveTooltip,
            ),
        ],
      ),
    );
  }

  String _statusLabel(BuildContext context, UserStatus status) {
    final l10n = context.l10n;
    return switch (status) {
      UserStatus.ready => l10n.memberStatusReady,
      UserStatus.online => l10n.memberStatusOnline,
      UserStatus.away => l10n.memberStatusAway,
      UserStatus.offline => l10n.memberStatusOffline,
    };
  }

  Color _statusColor(UserStatus status) {
    return switch (status) {
      UserStatus.ready => AppColors.success,
      UserStatus.online => AppColors.primary,
      UserStatus.away => AppColors.warning,
      UserStatus.offline => AppColors.textTertiary,
    };
  }

  String _roleLabel(String role) {
    final l10n = currentAppLocalizations();
    return switch (role.toLowerCase()) {
      'owner' => l10n.memberRoleOwner,
      'admin' => l10n.memberRoleAdmin,
      _ => l10n.groupSettingsRoleMember,
    };
  }
}

class _JoinRequestRow extends StatelessWidget {
  const _JoinRequestRow({
    required this.request,
    required this.onApprove,
    required this.onDeny,
  });

  final JoinRequest request;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          UserAvatar(
            imageUrl: request.user.avatarUrl,
            displayName: request.user.displayName,
            size: 36,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.user.displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (request.createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(request.createdAt!),
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, size: 22),
            color: AppColors.success,
            onPressed: onApprove,
            tooltip: context.l10n.groupSettingsApproveTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined, size: 22),
            color: AppColors.error,
            onPressed: onDeny,
            tooltip: context.l10n.groupSettingsDenyTooltip,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    final l10n = currentAppLocalizations();
    if (diff.inDays > 0) return l10n.groupSettingsTimeAgoDays(diff.inDays);
    if (diff.inHours > 0) return l10n.groupSettingsTimeAgoHours(diff.inHours);
    return l10n.groupSettingsTimeAgoMinutes(diff.inMinutes);
  }
}
