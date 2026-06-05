import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/providers/presence_provider.dart';
import '../../../../shared/widgets/avatar_with_status.dart';
import '../../../../shared/widgets/status_indicator.dart';
import '../../domain/membership_model.dart';

class MemberList extends StatelessWidget {
  const MemberList({
    super.key,
    required this.groupId,
    required this.members,
  });

  final String groupId;
  final List<GroupMember> members;

  static const _roleOrder = {'owner': 0, 'admin': 1, 'member': 2};

  List<GroupMember> get _sortedMembers {
    final sorted = List<GroupMember>.from(members);
    sorted.sort((a, b) {
      final aOrder = _roleOrder[a.role.toLowerCase()] ?? 3;
      final bOrder = _roleOrder[b.role.toLowerCase()] ?? 3;
      return aOrder.compareTo(bOrder);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedMembers;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) =>
          _MemberTile(groupId: groupId, member: sorted[index]),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.groupId,
    required this.member,
  });

  final String groupId;
  final GroupMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      groupMemberStatusProvider((groupId: groupId, userId: member.userId)),
    );
    final roleBadge = _roleBadge(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AvatarWithStatus(
            imageUrl: member.avatarUrl,
            displayName: member.displayName,
            status: status,
            size: 36,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.displayName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (roleBadge != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      roleBadge,
                    ],
                  ],
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _roleBadge(BuildContext context) {
    final role = member.role.toLowerCase();
    final l10n = context.l10n;
    if (role == 'owner') {
      return _buildBadge(l10n.memberRoleOwner, AppColors.primary);
    } else if (role == 'admin') {
      return _buildBadge(l10n.memberRoleAdmin, AppColors.secondary);
    }
    return null;
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
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
}
