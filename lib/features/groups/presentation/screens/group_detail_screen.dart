import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/networking/api_error.dart';
import '../../../../core/networking/websocket_client.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/providers/presence_provider.dart';
import '../../../../shared/providers/websocket_provider.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_confirmation_dialog.dart';
import '../../../../shared/widgets/app_popup_menu_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/desktop_content_region.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/services/app_haptics.dart';
import '../../domain/coordination_model.dart';
import '../providers/group_coordination_provider.dart';
import '../providers/group_detail_provider.dart';
import '../providers/groups_provider.dart';
import '../widgets/invite_link_share.dart';
import '../widgets/member_list.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(groupDetailNotifierProvider(groupId));
    final l10n = context.l10n;

    return AppBackgroundSurface(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: detailAsync.value?.group.name ?? l10n.groupTitleFallback,
          contentWidth: DesktopContentWidth.reading,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          actions: detailAsync.value != null
              ? [
                  AppPopupMenuButton<_GroupAction>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppColors.textSecondary,
                    ),
                    onOpened: () {
                      ref.read(appHapticsProvider).selection();
                    },
                    onSelected: (action) {
                      ref.read(appHapticsProvider).selection();
                      _onMenuAction(context, ref, action, detailAsync.value!);
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: _GroupAction.invite,
                        child: _MenuRow(
                          icon: Icons.person_add_outlined,
                          label: l10n.groupDetailMenuInvite,
                        ),
                      ),
                      if (detailAsync.value!.canManageSettings)
                        PopupMenuItem(
                          value: _GroupAction.settings,
                          child: _MenuRow(
                            icon: Icons.settings_outlined,
                            label: l10n.groupDetailMenuSettings,
                            badgeCount:
                                detailAsync.value?.pendingRequests.length ?? 0,
                          ),
                        ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: _GroupAction.leave,
                        child: _MenuRow(
                          icon: Icons.logout,
                          label: l10n.groupDetailMenuLeave,
                          isDestructive: true,
                        ),
                      ),
                    ],
                  ),
                ]
              : null,
        ),
        body: detailAsync.when(
          loading: () => const DesktopContentRegion(
            width: DesktopContentWidth.reading,
            child: LoadingIndicator(),
          ),
          error: (error, _) => DesktopContentRegion(
            width: DesktopContentWidth.reading,
            child: ErrorDisplay(
              message: ApiError.userMessage(error, context.l10n),
              onRetry: () => ref
                  .read(groupDetailNotifierProvider(groupId).notifier)
                  .refresh(),
            ),
          ),
          data: (detail) => DesktopContentRegion(
            width: DesktopContentWidth.reading,
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.backgroundLight,
              onRefresh: () async {
                await ref
                    .read(groupDetailNotifierProvider(groupId).notifier)
                    .refresh();
                await ref.read(appHapticsProvider).refreshComplete();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (detail.group.description != null &&
                              detail.group.description!.isNotEmpty) ...[
                            GlassCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.groupDetailSectionAbout,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    detail.group.description!,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          GlassCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                _InfoChip(
                                  icon: Icons.people,
                                  label: l10n.joinGroupMembers(
                                    detail.members.length,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                _InfoChip(
                                  icon: detail.group.isDiscoverable
                                      ? Icons.public
                                      : Icons.lock,
                                  label: detail.group.isDiscoverable
                                      ? l10n.groupVisibilityPublic
                                      : l10n.groupVisibilityPrivate,
                                ),
                                if (detail.group.isDiscoverable) ...[
                                  const SizedBox(width: AppSpacing.md),
                                  _InfoChip(
                                    icon: detail.group.joinMode == 'open'
                                        ? Icons.open_in_new
                                        : Icons.approval,
                                    label: detail.group.joinMode == 'open'
                                        ? l10n.groupJoinModeOpenLabel
                                        : l10n.groupJoinModeApprovalLabel,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _ReadyToggleCard(groupId: groupId),
                          const SizedBox(height: AppSpacing.lg),
                          _CoordinationHubCard(groupId: groupId),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                      0,
                    ),
                    sliver: SliverFillRemaining(
                      hasScrollBody: false,
                      fillOverscroll: true,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.groupDetailSectionMembers,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          MemberList(groupId: groupId, members: detail.members),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onMenuAction(
    BuildContext context,
    WidgetRef ref,
    _GroupAction action,
    GroupDetailState detail,
  ) {
    switch (action) {
      case _GroupAction.invite:
        _showInviteSheet(context, detail.group.inviteCode);
        break;
      case _GroupAction.settings:
        context.goNamed(
          RouteNames.groupSettings,
          pathParameters: {'id': groupId},
        );
        break;
      case _GroupAction.leave:
        _showLeaveDialog(context, ref, detail);
        break;
    }
  }

  void _showInviteSheet(BuildContext context, String inviteCode) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: AppColors.glassBorder),
            left: BorderSide(color: AppColors.glassBorder),
            right: BorderSide(color: AppColors.glassBorder),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            InviteLinkShare(inviteCode: inviteCode),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showLeaveDialog(
    BuildContext context,
    WidgetRef ref,
    GroupDetailState detail,
  ) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text(
          context.l10n.groupDetailLeaveTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          detail.isOwner
              ? context.l10n.groupDetailOwnerLeaveMessage
              : context.l10n.groupDetailLeaveMessage,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: detail.isOwner
                ? () => Navigator.pop(ctx)
                : () async {
                    Navigator.pop(ctx);
                    try {
                      await ref
                          .read(groupsNotifierProvider.notifier)
                          .leaveGroup(groupId);
                      await ref.read(appHapticsProvider).destructiveConfirm();
                      if (context.mounted) context.pop();
                    } catch (error) {
                      if (context.mounted) {
                        AppToast.error(
                          context,
                          ApiError.userMessage(error, context.l10n),
                        );
                      }
                    }
                  },
            child: Text(
              detail.isOwner
                  ? context.l10n.commonClose
                  : context.l10n.groupDetailMenuLeave,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

enum _GroupAction { invite, settings, leave }

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: AppSpacing.sm + 4),
        Text(label, style: TextStyle(color: color, fontSize: 14)),
        if (badgeCount > 0) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$badgeCount',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ReadyToggleCard extends ConsumerWidget {
  const _ReadyToggleCard({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isReady = ref.watch(currentUserReadyProvider(groupId));
    final connectionState = ref.watch(websocketConnectionStateProvider);
    final isConnected = connectionState == WebSocketConnectionState.connected;
    final hintText = switch (connectionState) {
      WebSocketConnectionState.connected => l10n.groupDetailReadyToggleHint,
      WebSocketConnectionState.connecting =>
        l10n.groupDetailReadyToggleReconnectingHint,
      WebSocketConnectionState.disconnected =>
        l10n.groupDetailReadyToggleOfflineHint,
    };

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.groupDetailReadyToggleLabel,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  hintText,
                  style: TextStyle(
                    color: isConnected
                        ? AppColors.textSecondary
                        : AppColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isReady,
            activeThumbColor: AppColors.success,
            onChanged: isConnected
                ? (ready) => _handleReadyToggle(
                    context,
                    ref,
                    currentValue: isReady,
                    nextValue: ready,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _handleReadyToggle(
    BuildContext context,
    WidgetRef ref, {
    required bool currentValue,
    required bool nextValue,
  }) async {
    if (currentValue == nextValue) return;

    if (nextValue) {
      final confirmed = await showAppConfirmationDialog(
        context,
        title: context.l10n.groupDetailReadyConfirmTitle,
        message: context.l10n.groupDetailReadyConfirmMessage,
        confirmLabel: context.l10n.groupDetailReadyConfirmAction,
        cancelLabel: context.l10n.commonCancel,
      );
      if (!confirmed) return;
    }

    final changed = ref
        .read(presenceNotifierProvider.notifier)
        .toggleReady(groupId: groupId, ready: nextValue);
    if (!changed) return;

    await ref.read(appHapticsProvider).selection();
  }
}

class _CoordinationHubCard extends ConsumerWidget {
  const _CoordinationHubCard({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final coordinationAsync = ref.watch(
      groupCoordinationNotifierProvider(groupId),
    );
    final coordination = coordinationAsync.value;
    final nextSession = _findNextSession(coordination?.sessions);
    final upcomingWindowCount = _countUpcomingWindows(coordination?.windows);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.groupDetailCoordinationTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.groupDetailCoordinationSubtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          if (coordination != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _InfoChip(
                  icon: Icons.calendar_month_outlined,
                  label: l10n.groupCoordinationWindowsCount(upcomingWindowCount),
                ),
                _InfoChip(
                  icon: Icons.sports_esports_outlined,
                  label: l10n.groupCoordinationSessionsCount(
                    coordination.sessions.length,
                  ),
                ),
                _InfoChip(
                  icon: Icons.bolt_outlined,
                  label: l10n.groupCoordinationActivityCount(
                    coordination.activity.length,
                  ),
                ),
              ],
            ),
          ],
          if (nextSession != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.groupDetailCoordinationNextSession(
                nextSession.title ??
                    nextSession.game ??
                    l10n.groupCoordinationUntitledSession,
              ),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          GlassButton(
            variant: GlassButtonVariant.secondary,
            onPressed: () => context.goNamed(
              RouteNames.groupCoordination,
              pathParameters: {'id': groupId},
            ),
            child: Text(l10n.groupDetailCoordinationAction),
          ),
        ],
      ),
    );
  }

  GroupSession? _findNextSession(List<GroupSession>? sessions) {
    if (sessions == null || sessions.isEmpty) {
      return null;
    }
    final now = DateTime.now();
    for (final session in sessions) {
      if (session.status == 'cancelled') {
        continue;
      }
      if (!session.startsAt.isBefore(now)) {
        return session;
      }
    }
    return null;
  }

  int _countUpcomingWindows(List<ScheduledReadyWindow>? windows) {
    if (windows == null || windows.isEmpty) {
      return 0;
    }
    final now = DateTime.now();
    return windows.where((window) => window.endsAt.toLocal().isAfter(now)).length;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppChip.inline(label: label, icon: icon);
  }
}
