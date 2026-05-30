import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/networking/api_error.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../../../../shared/widgets/loading_indicator.dart';
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
        AppToast.success(context, 'Group updated');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.error(context, ApiError.userMessage(e));
      }
    }
  }

  Future<void> _removeMember(String userId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        title: const Text(
          'Remove Member',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Remove $displayName from this group?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: AppColors.error)),
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
        AppToast.success(context, '$displayName removed');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, ApiError.userMessage(e));
      }
    }
  }

  Future<void> _approveRequest(String requestId) async {
    try {
      await ref
          .read(groupDetailNotifierProvider(widget.groupId).notifier)
          .resolveRequest(requestId, approved: true);
      if (mounted) {
        AppToast.success(context, 'Request approved');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, ApiError.userMessage(e));
      }
    }
  }

  Future<void> _denyRequest(String requestId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        title: const Text(
          'Deny Request',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Deny join request from $displayName?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Deny', style: TextStyle(color: AppColors.error)),
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
        AppToast.info(context, 'Request denied');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, ApiError.userMessage(e));
      }
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        title: const Text(
          'Delete Group',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'This action cannot be undone. All members will be removed.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
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
        AppToast.error(context, ApiError.userMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(groupDetailNotifierProvider(widget.groupId));

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
          title: 'Group Settings',
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
                    : const Text(
                        'Save',
                        style: TextStyle(
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
            child: Text(error.toString(),
                style: const TextStyle(color: AppColors.textSecondary)),
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
                  const _SectionLabel('GROUP INFO'),
                  const SizedBox(height: AppSpacing.sm),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        GlassInput(
                          controller: _nameController,
                          label: 'Group Name',
                          prefixIcon: Icons.group_outlined,
                          onChanged: (_) => _markChanged(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        GlassInput(
                          controller: _descriptionController,
                          label: 'Description',
                          prefixIcon: Icons.notes_outlined,
                          maxLines: 3,
                          onChanged: (_) => _markChanged(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _SectionLabel('VISIBILITY'),
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
                          title: 'Discoverable',
                          subtitle:
                              'Allow this group to appear in search',
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
                            title: 'Join Mode',
                            options: const {
                              'open': 'Open — anyone can join',
                              'approval':
                                  'Approval — requests reviewed by admins',
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
                      'MEMBERS (${detail.members.length})'),
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
                        'PENDING REQUESTS (${detail.pendingRequests.length})'),
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
                  const _SectionLabel('DANGER ZONE'),
                  const SizedBox(height: AppSpacing.sm),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Deleting this group is permanent and will remove all members.',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        GlassButton(
                          onPressed: _deleteGroup,
                          variant: GlassButtonVariant.ghost,
                          child: const Text(
                            'Delete Group',
                            style: TextStyle(color: AppColors.error),
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

class _MemberSettingsRow extends StatelessWidget {
  const _MemberSettingsRow({
    required this.member,
    this.onRemove,
  });

  final dynamic member;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final role = member.role as String;
    final isOwner = role.toLowerCase() == 'owner';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          UserAvatar(
            imageUrl: member.avatarUrl as String?,
            displayName: member.displayName as String,
            size: 36,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName as String,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
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
              tooltip: 'Remove',
            ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    return switch (role.toLowerCase()) {
      'owner' => 'Owner',
      'admin' => 'Admin',
      _ => 'Member',
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
            tooltip: 'Approve',
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined, size: 22),
            color: AppColors.error,
            onPressed: onDeny,
            tooltip: 'Deny',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}
