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
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_confirmation_dialog.dart';
import '../../../../shared/widgets/app_popup_menu_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/desktop_content_region.dart';
import '../../../../shared/widgets/avatar_with_status.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/status_indicator.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../shared/widgets/app_switch_row.dart';
import '../../../../shared/services/app_haptics.dart';
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
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _hasChanges = false;
      });
      final successMessage = context.l10n.groupSettingsUpdated;
      await ref.read(appHapticsProvider).success();
      if (!mounted) return;
      AppToast.success(context, successMessage);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.error(context, ApiError.userMessage(e, context.l10n));
      }
    }
  }

  Future<void> _removeMember(String userId, String displayName) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: context.l10n.groupSettingsRemoveMemberTitle,
      message: context.l10n.groupSettingsRemoveMemberMessage(displayName),
      confirmLabel: context.l10n.commonRemove,
      cancelLabel: context.l10n.commonCancel,
      variant: AppConfirmationVariant.destructive,
    );
    if (!confirmed) return;

    try {
      final repo = ref.read(groupsRepositoryProvider);
      await repo.removeMember(widget.groupId, userId);
      ref.read(groupDetailNotifierProvider(widget.groupId).notifier).refresh();
      if (!mounted) return;
      final successMessage = context.l10n.groupSettingsMemberRemoved(
        displayName,
      );
      await ref.read(appHapticsProvider).destructiveConfirm();
      if (!mounted) return;
      AppToast.success(context, successMessage);
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
      if (!mounted) return;
      final successMessage = context.l10n.groupSettingsRequestApproved;
      await ref.read(appHapticsProvider).success();
      if (!mounted) return;
      AppToast.success(context, successMessage);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, ApiError.userMessage(e, context.l10n));
      }
    }
  }

  Future<void> _denyRequest(String requestId, String displayName) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: context.l10n.groupSettingsDenyRequestTitle,
      message: context.l10n.groupSettingsDenyRequestMessage(displayName),
      confirmLabel: context.l10n.commonDeny,
      cancelLabel: context.l10n.commonCancel,
      variant: AppConfirmationVariant.destructive,
    );
    if (!confirmed) return;

    try {
      await ref
          .read(groupDetailNotifierProvider(widget.groupId).notifier)
          .resolveRequest(requestId, approved: false);
      if (!mounted) return;
      final infoMessage = context.l10n.groupSettingsRequestDenied;
      await ref.read(appHapticsProvider).destructiveConfirm();
      if (!mounted) return;
      AppToast.info(context, infoMessage);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, ApiError.userMessage(e, context.l10n));
      }
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: context.l10n.groupSettingsDeleteTitle,
      message: context.l10n.groupSettingsDeleteMessage,
      confirmLabel: context.l10n.commonDelete,
      cancelLabel: context.l10n.commonCancel,
      variant: AppConfirmationVariant.destructive,
    );
    if (!confirmed) return;

    try {
      await ref.read(groupsNotifierProvider.notifier).delete(widget.groupId);
      if (!mounted) return;
      await ref.read(appHapticsProvider).destructiveConfirm();
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (mounted) {
        AppToast.error(context, ApiError.userMessage(e, context.l10n));
      }
    }
  }

  Future<void> _changeMemberRole(
    String userId,
    String displayName, {
    required String nextRole,
  }) async {
    final l10n = context.l10n;
    final confirmed = await showAppConfirmationDialog(
      context,
      title: nextRole == 'admin'
          ? l10n.groupSettingsPromoteTitle
          : l10n.groupSettingsDemoteTitle,
      message: nextRole == 'admin'
          ? l10n.groupSettingsPromoteMessage(displayName)
          : l10n.groupSettingsDemoteMessage(displayName),
      confirmLabel: nextRole == 'admin'
          ? l10n.groupSettingsPromoteAction
          : l10n.groupSettingsDemoteAction,
      cancelLabel: l10n.commonCancel,
    );
    if (!confirmed) return;

    try {
      await ref
          .read(groupDetailNotifierProvider(widget.groupId).notifier)
          .updateMemberRole(userId, nextRole);
      if (!mounted) return;
      final successMessage = nextRole == 'admin'
          ? l10n.groupSettingsPromoted(displayName)
          : l10n.groupSettingsDemoted(displayName);
      await ref.read(appHapticsProvider).destructiveConfirm();
      if (!mounted) return;
      AppToast.success(context, successMessage);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, ApiError.userMessage(e, context.l10n));
      }
    }
  }

  Future<void> _transferOwnership(String userId, String displayName) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: context.l10n.groupSettingsTransferOwnershipTitle,
      message: context.l10n.groupSettingsTransferOwnershipMessage(displayName),
      confirmLabel: context.l10n.groupSettingsTransferOwnershipAction,
      cancelLabel: context.l10n.commonCancel,
    );
    if (!confirmed) return;

    try {
      await ref
          .read(groupDetailNotifierProvider(widget.groupId).notifier)
          .transferOwnership(userId);
      if (!mounted) return;
      final successMessage = context.l10n.groupSettingsOwnershipTransferred(
        displayName,
      );
      await ref.read(appHapticsProvider).destructiveConfirm();
      if (!mounted) return;
      AppToast.success(context, successMessage);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, ApiError.userMessage(e, context.l10n));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(groupDetailNotifierProvider(widget.groupId));
    final l10n = context.l10n;
    final canManageSettings = detailAsync.value?.canManageSettings ?? false;

    return AppBackgroundSurface(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: l10n.groupSettingsTitle,
          contentWidth: DesktopContentWidth.wide,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (_hasChanges && canManageSettings)
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
          loading: () => const DesktopContentRegion(
            width: DesktopContentWidth.wide,
            child: Center(child: LoadingIndicator()),
          ),
          error: (error, _) => DesktopContentRegion(
            width: DesktopContentWidth.wide,
            child: Center(
              child: Text(
                ApiError.userMessage(error, context.l10n),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
          data: (detail) {
            _initFromGroup(detail);
            if (!detail.canManageSettings) {
              return DesktopContentRegion(
                width: DesktopContentWidth.wide,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      l10n.errorNoPermission,
                      style: const TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }
            return DesktopContentRegion(
              width: DesktopContentWidth.wide,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionLabel(
                      l10n.groupSettingsSectionGroupInfo.toUpperCase(),
                    ),
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
                    _SectionLabel(
                      l10n.groupSettingsSectionVisibility.toUpperCase(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        children: [
                          AppSwitchRow(
                            icon: Icons.explore_outlined,
                            title: l10n.createGroupDiscoverableTitle,
                            subtitle: l10n.createGroupDiscoverableSubtitle,
                            value: _isDiscoverable,
                            onChanged: detail.canManageSettings
                                ? (v) {
                                    setState(() => _isDiscoverable = v);
                                    _markChanged();
                                    ref.read(appHapticsProvider).selection();
                                  }
                                : null,
                          ),
                          if (_isDiscoverable) ...[
                            const Divider(height: 1),
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
                              enabled: detail.canManageSettings,
                              onChanged: (v) {
                                setState(() => _joinMode = v);
                                _markChanged();
                                ref.read(appHapticsProvider).selection();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionLabel(
                      l10n
                          .groupSettingsSectionMembers(detail.members.length)
                          .toUpperCase(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < detail.members.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            _MemberSettingsRow(
                              groupId: widget.groupId,
                              member: detail.members[i],
                              onRemove:
                                  detail.canRemoveMember(detail.members[i])
                                  ? () => _removeMember(
                                      detail.members[i].userId,
                                      detail.members[i].displayName,
                                    )
                                  : null,
                              onPromote: detail.canPromote(detail.members[i])
                                  ? () => _changeMemberRole(
                                      detail.members[i].userId,
                                      detail.members[i].displayName,
                                      nextRole: 'admin',
                                    )
                                  : null,
                              onDemote: detail.canDemote(detail.members[i])
                                  ? () => _changeMemberRole(
                                      detail.members[i].userId,
                                      detail.members[i].displayName,
                                      nextRole: 'member',
                                    )
                                  : null,
                              onTransferOwnership:
                                  detail.canTransferOwnershipTo(
                                    detail.members[i],
                                  )
                                  ? () => _transferOwnership(
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
                    if (detail.canManageRequests &&
                        detail.pendingRequests.isNotEmpty) ...[
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
                            for (
                              var i = 0;
                              i < detail.pendingRequests.length;
                              i++
                            ) ...[
                              if (i > 0) const Divider(height: 1),
                              _JoinRequestRow(
                                request: detail.pendingRequests[i],
                                onApprove: () => _approveRequest(
                                  detail.pendingRequests[i].id,
                                ),
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
                    if (detail.canDeleteGroup) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _SectionLabel(
                        l10n.groupSettingsSectionDangerZone.toUpperCase(),
                      ),
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
                  ],
                ),
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

class _SettingsRadio extends StatelessWidget {
  const _SettingsRadio({
    required this.icon,
    required this.title,
    required this.options,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final Map<String, String> options;
  final String value;
  final bool enabled;
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
            child: Icon(icon, size: 20, color: AppColors.textTertiary),
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
                    onTap: enabled ? () => onChanged(entry.key) : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs + 2,
                      ),
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
    this.onPromote,
    this.onDemote,
    this.onTransferOwnership,
  });

  final String groupId;
  final dynamic member;
  final VoidCallback? onRemove;
  final VoidCallback? onPromote;
  final VoidCallback? onDemote;
  final VoidCallback? onTransferOwnership;

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
                    color: isOwner ? AppColors.primary : AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onPromote != null ||
              onDemote != null ||
              onTransferOwnership != null ||
              onRemove != null)
            AppPopupMenuButton<_MemberAction>(
              icon: const Icon(
                Icons.more_horiz,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onOpened: () {
                ref.read(appHapticsProvider).selection();
              },
              onSelected: (action) {
                ref.read(appHapticsProvider).selection();
                switch (action) {
                  case _MemberAction.promote:
                    onPromote?.call();
                    break;
                  case _MemberAction.demote:
                    onDemote?.call();
                    break;
                  case _MemberAction.transferOwnership:
                    onTransferOwnership?.call();
                    break;
                  case _MemberAction.remove:
                    onRemove?.call();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (onPromote != null)
                  PopupMenuItem(
                    value: _MemberAction.promote,
                    child: Text(context.l10n.groupSettingsPromoteAction),
                  ),
                if (onDemote != null)
                  PopupMenuItem(
                    value: _MemberAction.demote,
                    child: Text(context.l10n.groupSettingsDemoteAction),
                  ),
                if (onTransferOwnership != null)
                  PopupMenuItem(
                    value: _MemberAction.transferOwnership,
                    child: Text(
                      context.l10n.groupSettingsTransferOwnershipAction,
                    ),
                  ),
                if (onRemove != null)
                  PopupMenuItem(
                    value: _MemberAction.remove,
                    child: Text(
                      context.l10n.commonRemove,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
              ],
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

enum _MemberAction { promote, demote, transferOwnership, remove }

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
