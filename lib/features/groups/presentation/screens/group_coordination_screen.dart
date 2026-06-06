import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/networking/api_error.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_confirmation_dialog.dart';
import '../../../../shared/widgets/app_dropdown_selector.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/desktop_content_region.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/services/app_haptics.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/coordination_model.dart';
import '../providers/group_detail_provider.dart';
import '../providers/group_coordination_provider.dart';

class GroupCoordinationScreen extends ConsumerStatefulWidget {
  const GroupCoordinationScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupCoordinationScreen> createState() =>
      _GroupCoordinationScreenState();
}

class _GroupCoordinationScreenState
    extends ConsumerState<GroupCoordinationScreen> {
  @override
  Widget build(BuildContext context) {
    final coordinationAsync = ref.watch(
      groupCoordinationNotifierProvider(widget.groupId),
    );
    final detailAsync = ref.watch(groupDetailNotifierProvider(widget.groupId));

    return AppBackgroundSurface(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: context.l10n.groupCoordinationTitle,
          contentWidth: DesktopContentWidth.reading,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: coordinationAsync.when(
          loading: () => const DesktopContentRegion(
            width: DesktopContentWidth.reading,
            child: LoadingIndicator(),
          ),
          error: (error, _) => DesktopContentRegion(
            width: DesktopContentWidth.reading,
            child: ErrorDisplay(
              message: ApiError.userMessage(error, context.l10n),
              onRetry: () => ref
                  .read(
                    groupCoordinationNotifierProvider(widget.groupId).notifier,
                  )
                  .refresh(),
            ),
          ),
          data: (coordination) {
            final detailState = detailAsync.value;
            if (detailAsync.hasError) {
              return DesktopContentRegion(
                width: DesktopContentWidth.reading,
                child: ErrorDisplay(
                  message: ApiError.userMessage(
                    detailAsync.error!,
                    context.l10n,
                  ),
                  onRetry: () => ref
                      .read(
                        groupDetailNotifierProvider(widget.groupId).notifier,
                      )
                      .refresh(),
                ),
              );
            }
            final currentUserId =
                ref
                    .watch(authNotifierProvider)
                    .value
                    ?.maybeWhen(
                      authenticated: (user) => user.id,
                      orElse: () => detailState?.currentUserId,
                    ) ??
                detailState?.currentUserId;
            final currentUserRole = detailState?.currentUserRole;
            return DesktopContentRegion(
              width: DesktopContentWidth.reading,
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.backgroundLight,
                onRefresh: () async {
                  await ref
                      .read(
                        groupCoordinationNotifierProvider(
                          widget.groupId,
                        ).notifier,
                      )
                      .refresh();
                  await ref.read(appHapticsProvider).refreshComplete();
                },
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    _SummaryCard(
                      windowCount: coordination.windows.length,
                      sessionCount: coordination.sessions.length,
                      activityCount: coordination.activity.length,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _UpcomingWindowsSection(
                      windows: coordination.windows,
                      currentUserId: currentUserId,
                      currentUserRole: currentUserRole,
                      onAdd: () => _showWindowEditor(context, ref),
                      onEdit: (window) => _showWindowEditor(
                        context,
                        ref,
                        initialWindow: window,
                      ),
                      onViewAll: (windows) =>
                          _showUpcomingWindowsSheet(context, windows),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SessionsSection(
                      sessions: coordination.sessions,
                      groupId: widget.groupId,
                      currentUserId: currentUserId,
                      currentUserRole: currentUserRole,
                      pendingRsvpSessionIds: coordination.pendingRsvpSessionIds,
                      onAdd: () => _showSessionEditor(context, ref),
                      onEdit: (session) => _showSessionEditor(
                        context,
                        ref,
                        initialSession: session,
                      ),
                      onDelete: (session) =>
                          _confirmDeleteSession(context, ref, session),
                      onRsvp: _handleSessionRsvp,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ActivitySection(activity: coordination.activity),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showWindowEditor(
    BuildContext context,
    WidgetRef ref, {
    ScheduledReadyWindow? initialWindow,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: _WindowEditorSheet(
            initialWindow: initialWindow,
            onSave: (startsAt, endsAt) async {
              final notifier = ref.read(
                groupCoordinationNotifierProvider(widget.groupId).notifier,
              );
              if (initialWindow == null) {
                await notifier.createScheduledReady(
                  startsAt: startsAt,
                  endsAt: endsAt,
                );
              } else {
                await notifier.updateScheduledReady(
                  initialWindow.id,
                  startsAt: startsAt,
                  endsAt: endsAt,
                );
              }
              await ref.read(appHapticsProvider).success();
            },
            onDelete: initialWindow == null
                ? null
                : () async {
                    await ref
                        .read(
                          groupCoordinationNotifierProvider(
                            widget.groupId,
                          ).notifier,
                        )
                        .deleteScheduledReady(initialWindow.id);
                    await ref.read(appHapticsProvider).destructiveConfirm();
                  },
          ),
        );
      },
    );
  }

  Future<void> _showSessionEditor(
    BuildContext context,
    WidgetRef ref, {
    GroupSession? initialSession,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: _SessionEditorSheet(
            initialSession: initialSession,
            onSave: (title, game, notes, startsAt, status) async {
              final notifier = ref.read(
                groupCoordinationNotifierProvider(widget.groupId).notifier,
              );
              if (initialSession == null) {
                await notifier.createSession(
                  title: title,
                  game: game,
                  notes: notes,
                  startsAt: startsAt,
                );
              } else {
                await notifier.updateSession(
                  initialSession.id,
                  title: title,
                  game: game,
                  notes: notes,
                  startsAt: startsAt,
                  status: status,
                );
              }
              final haptics = ref.read(appHapticsProvider);
              if (status == 'cancelled') {
                await haptics.destructiveConfirm();
              } else {
                await haptics.success();
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteSession(
    BuildContext context,
    WidgetRef ref,
    GroupSession session,
  ) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: context.l10n.groupCoordinationDeleteSessionConfirmTitle,
      message: context.l10n.groupCoordinationDeleteSessionConfirmMessage,
      confirmLabel: context.l10n.groupCoordinationDeleteSessionAction,
      cancelLabel: context.l10n.commonCancel,
      variant: AppConfirmationVariant.destructive,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref
          .read(groupCoordinationNotifierProvider(widget.groupId).notifier)
          .deleteSession(session.id);
      await ref.read(appHapticsProvider).destructiveConfirm();
    } catch (error) {
      if (!context.mounted) return;
      final message = error is DioException && error.response?.statusCode == 405
          ? context.l10n.errorServer
          : ApiError.userMessage(error, context.l10n);
      AppToast.error(context, message);
    }
  }

  Future<void> _showUpcomingWindowsSheet(
    BuildContext context,
    List<ScheduledReadyWindow> windows,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final currentUserId = ref
            .read(authNotifierProvider)
            .value
            ?.maybeWhen(authenticated: (user) => user.id, orElse: () => null);
        final currentUserRole = ref
            .read(groupDetailNotifierProvider(widget.groupId))
            .value
            ?.currentUserRole;
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: _UpcomingWindowsSheet(
            windows: windows,
            currentUserId: currentUserId,
            currentUserRole: currentUserRole,
            onEdit: (window) {
              Navigator.of(sheetContext).pop();
              _showWindowEditor(context, ref, initialWindow: window);
            },
          ),
        );
      },
    );
  }

  Future<void> _handleSessionRsvp(String sessionId, String response) async {
    try {
      await ref
          .read(groupCoordinationNotifierProvider(widget.groupId).notifier)
          .rsvpToSession(sessionId, response);
      await ref.read(appHapticsProvider).success();
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, ApiError.userMessage(error, context.l10n));
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.windowCount,
    required this.sessionCount,
    required this.activityCount,
  });

  final int windowCount;
  final int sessionCount;
  final int activityCount;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.groupCoordinationTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.groupCoordinationSubtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _SummaryChip(
                icon: Icons.calendar_month_outlined,
                label: context.l10n.groupCoordinationWindowsCount(windowCount),
              ),
              _SummaryChip(
                icon: Icons.sports_esports_outlined,
                label: context.l10n.groupCoordinationSessionsCount(
                  sessionCount,
                ),
              ),
              _SummaryChip(
                icon: Icons.bolt_outlined,
                label: context.l10n.groupCoordinationActivityCount(
                  activityCount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingWindowsSection extends StatelessWidget {
  const _UpcomingWindowsSection({
    required this.windows,
    required this.currentUserId,
    required this.currentUserRole,
    required this.onAdd,
    required this.onEdit,
    required this.onViewAll,
  });

  static const _previewLimit = 5;

  final List<ScheduledReadyWindow> windows;
  final String? currentUserId;
  final String? currentUserRole;
  final VoidCallback onAdd;
  final ValueChanged<ScheduledReadyWindow> onEdit;
  final ValueChanged<List<ScheduledReadyWindow>> onViewAll;

  @override
  Widget build(BuildContext context) {
    final upcomingWindows = _upcomingWindows(windows);
    final previewWindows = upcomingWindows.take(_previewLimit).toList();
    final remainingCount = upcomingWindows.length - previewWindows.length;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: context.l10n.groupCoordinationUpcomingWindowsTitle,
            actionLabel: context.l10n.groupCoordinationCalendarAdd,
            onAction: onAdd,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (upcomingWindows.isEmpty)
            Text(
              context.l10n.groupCoordinationUpcomingWindowsEmpty,
              style: const TextStyle(color: AppColors.textSecondary),
            )
          else ...[
            ..._buildReadyWindowAgenda(
              context,
              previewWindows,
              currentUserId: currentUserId,
              currentUserRole: currentUserRole,
              onEdit: onEdit,
            ),
            if (remainingCount > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => onViewAll(upcomingWindows),
                  child: Text(
                    context.l10n.groupCoordinationUpcomingWindowsViewAll(
                      remainingCount,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _UpcomingWindowsSheet extends StatelessWidget {
  const _UpcomingWindowsSheet({
    required this.windows,
    required this.currentUserId,
    required this.currentUserRole,
    required this.onEdit,
  });

  final List<ScheduledReadyWindow> windows;
  final String? currentUserId;
  final String? currentUserRole;
  final ValueChanged<ScheduledReadyWindow> onEdit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: GlassCard(
        margin: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.groupCoordinationUpcomingWindowsSheetTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView(
                children: _buildReadyWindowAgenda(
                  context,
                  windows,
                  currentUserId: currentUserId,
                  currentUserRole: currentUserRole,
                  onEdit: onEdit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<ScheduledReadyWindow> _upcomingWindows(
  List<ScheduledReadyWindow> windows,
) {
  final now = DateTime.now();
  final upcoming = windows
      .where((window) => window.endsAt.toLocal().isAfter(now))
      .toList();
  upcoming.sort((a, b) => a.startsAt.compareTo(b.startsAt));
  return upcoming;
}

List<Widget> _buildReadyWindowAgenda(
  BuildContext context,
  List<ScheduledReadyWindow> windows, {
  required String? currentUserId,
  required String? currentUserRole,
  required ValueChanged<ScheduledReadyWindow> onEdit,
}) {
  final grouped = <DateTime, List<ScheduledReadyWindow>>{};
  for (final window in windows) {
    final date = DateTime(
      window.startsAt.toLocal().year,
      window.startsAt.toLocal().month,
      window.startsAt.toLocal().day,
    );
    grouped.putIfAbsent(date, () => []).add(window);
  }
  final dates = grouped.keys.toList()..sort();
  return [
    for (var index = 0; index < dates.length; index++) ...[
      if (index > 0)
        Divider(
          key: Key('agenda-day-divider-${_agendaDateKey(dates[index])}'),
          height: AppSpacing.lg,
          color: AppColors.glassBorder,
        ),
      _AgendaDayHeader(
        key: Key('agenda-day-header-${_agendaDateKey(dates[index])}'),
        date: dates[index],
      ),
      for (final window in grouped[dates[index]]!)
        _ReadyWindowTile(
          window: window,
          currentUserId: currentUserId,
          currentUserRole: currentUserRole,
          onEdit: onEdit,
        ),
    ],
  ];
}

String _agendaDateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

class _AgendaDayHeader extends StatelessWidget {
  const _AgendaDayHeader({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _formatDayHeading(context, date),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyWindowTile extends StatelessWidget {
  const _ReadyWindowTile({
    required this.window,
    required this.currentUserId,
    required this.currentUserRole,
    required this.onEdit,
  });

  final ScheduledReadyWindow window;
  final String? currentUserId;
  final String? currentUserRole;
  final ValueChanged<ScheduledReadyWindow> onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        window.displayName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (window.userId == currentUserId) ...[
                      const SizedBox(width: AppSpacing.xs),
                      AppChip.surface(
                        label: context.l10n.groupCoordinationOwnedByYou,
                        compact: true,
                        backgroundColor: AppColors.glassSurface,
                        textColor: AppColors.textSecondary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimeRange(context, window.startsAt, window.endsAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (_canEditReadyWindow(window, currentUserId, currentUserRole))
            IconButton(
              onPressed: () => onEdit(window),
              tooltip: context.l10n.groupCoordinationEditWindowTitle,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

bool _canEditReadyWindow(
  ScheduledReadyWindow window,
  String? currentUserId,
  String? currentUserRole,
) {
  if (window.userId == currentUserId) {
    return true;
  }
  return currentUserRole == 'owner' || currentUserRole == 'admin';
}

class _SessionsSection extends StatelessWidget {
  const _SessionsSection({
    required this.sessions,
    required this.groupId,
    required this.currentUserId,
    required this.currentUserRole,
    required this.pendingRsvpSessionIds,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRsvp,
  });

  final List<GroupSession> sessions;
  final String groupId;
  final String? currentUserId;
  final String? currentUserRole;
  final Set<String> pendingRsvpSessionIds;
  final VoidCallback onAdd;
  final ValueChanged<GroupSession> onEdit;
  final ValueChanged<GroupSession> onDelete;
  final Future<void> Function(String sessionId, String response) onRsvp;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: context.l10n.groupCoordinationSessionsTitle,
            actionLabel: context.l10n.groupCoordinationSessionAdd,
            onAction: onAdd,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (sessions.isEmpty)
            Text(
              context.l10n.groupCoordinationSessionsEmpty,
              style: const TextStyle(color: AppColors.textSecondary),
            )
          else
            for (final session in sessions)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _SessionCard(
                  session: session,
                  currentUserId: currentUserId,
                  currentUserRole: currentUserRole,
                  isUpdatingRsvp: pendingRsvpSessionIds.contains(session.id),
                  onOpenDetails: () => _SessionDetailSheet.show(
                    context,
                    groupId: groupId,
                    session: session,
                    onRsvp: onRsvp,
                  ),
                  onEdit: () => onEdit(session),
                  onDelete: () => onDelete(session),
                ),
              ),
        ],
      ),
    );
  }
}

enum _SessionCardAction { edit, delete }

class _SessionCard extends ConsumerWidget {
  const _SessionCard({
    required this.session,
    required this.currentUserId,
    required this.currentUserRole,
    required this.isUpdatingRsvp,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final GroupSession session;
  final String? currentUserId;
  final String? currentUserRole;
  final bool isUpdatingRsvp;
  final VoidCallback onOpenDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = _countSessionRsvps(session.rsvps);

    return GestureDetector(
      key: Key('session-card-${session.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref.read(appHapticsProvider).selection();
        onOpenDetails();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.glassSurfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title ??
                            session.game ??
                            context.l10n.groupCoordinationUntitledSession,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (session.game != null && session.title != session.game)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            session.game!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatDateTime(context, session.startsAt),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.l10n.groupCoordinationProposedBy(
                          session.proposedByDisplayName,
                        ),
                        style: const TextStyle(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                if (_canEditSession())
                  PopupMenuButton<_SessionCardAction>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppColors.textSecondary,
                    ),
                    onOpened: () {
                      ref.read(appHapticsProvider).selection();
                    },
                    onSelected: (action) {
                      ref.read(appHapticsProvider).selection();
                      if (action == _SessionCardAction.edit) {
                        onEdit();
                      } else {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _SessionCardAction.edit,
                        child: Text(
                          context.l10n.groupCoordinationEditSessionAction,
                        ),
                      ),
                      PopupMenuItem(
                        value: _SessionCardAction.delete,
                        child: Text(
                          context.l10n.groupCoordinationDeleteSessionAction,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _Pill(label: _statusLabel(context, session.status)),
                _SessionRsvpCountChip(
                  key: Key('session-rsvp-count-in-${session.id}'),
                  icon: Icons.check_circle_outline,
                  count: counts.inCount,
                ),
                _SessionRsvpCountChip(
                  key: Key('session-rsvp-count-maybe-${session.id}'),
                  icon: Icons.help_outline,
                  count: counts.maybeCount,
                ),
                _SessionRsvpCountChip(
                  key: Key('session-rsvp-count-out-${session.id}'),
                  icon: Icons.cancel_outlined,
                  count: counts.outCount,
                ),
              ],
            ),
            if (session.notes != null && session.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                session.notes!,
                key: Key('session-notes-preview-${session.id}'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.open_in_full_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  context.l10n.commonViewDetails,
                  style: const TextStyle(color: AppColors.textTertiary),
                ),
              ],
            ),
            if (isUpdatingRsvp) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.groupCoordinationRsvpUpdating,
                style: const TextStyle(color: AppColors.textTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canEditSession() {
    if (session.proposedBy == currentUserId) {
      return true;
    }
    return currentUserRole == 'owner' || currentUserRole == 'admin';
  }
}

class _SessionDetailSheet extends ConsumerWidget {
  const _SessionDetailSheet({
    required this.groupId,
    required this.initialSession,
    required this.onRsvp,
  });

  final String groupId;
  final GroupSession initialSession;
  final Future<void> Function(String sessionId, String response) onRsvp;

  static Future<void> show(
    BuildContext context, {
    required String groupId,
    required GroupSession session,
    required Future<void> Function(String sessionId, String response) onRsvp,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: _SessionDetailSheet(
            groupId: groupId,
            initialSession: session,
            onRsvp: onRsvp,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordination = ref.watch(groupCoordinationNotifierProvider(groupId));
    final liveSession = _findSessionById(
      coordination.value?.sessions ?? const [],
      initialSession.id,
    );
    if (liveSession == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }
    final session = liveSession;
    final currentUserId = ref
        .watch(authNotifierProvider)
        .value
        ?.maybeWhen(authenticated: (user) => user.id, orElse: () => null);
    final currentRsvp = _findCurrentRsvp(session.rsvps, currentUserId);
    final isUpdating =
        coordination.value?.pendingRsvpSessionIds.contains(session.id) ?? false;

    final groupedResponses = {
      'in': session.rsvps.where((item) => item.response == 'in').toList(),
      'maybe': session.rsvps.where((item) => item.response == 'maybe').toList(),
      'out': session.rsvps.where((item) => item.response == 'out').toList(),
    };

    return SafeArea(
      top: false,
      child: GlassCard(
        key: Key('session-detail-sheet-${session.id}'),
        margin: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title ??
                            session.game ??
                            context.l10n.groupCoordinationUntitledSession,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (session.game != null && session.title != session.game)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            session.game!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatDateTime(context, session.startsAt),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.l10n.groupCoordinationProposedBy(
                          session.proposedByDisplayName,
                        ),
                        style: const TextStyle(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _Pill(label: _statusLabel(context, session.status)),
                _SessionRsvpCountChip(
                  icon: Icons.check_circle_outline,
                  count: groupedResponses['in']!.length,
                ),
                _SessionRsvpCountChip(
                  icon: Icons.help_outline,
                  count: groupedResponses['maybe']!.length,
                ),
                _SessionRsvpCountChip(
                  icon: Icons.cancel_outlined,
                  count: groupedResponses['out']!.length,
                ),
              ],
            ),
            if (session.notes != null && session.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.l10n.groupCoordinationFieldNotes,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                session.notes!,
                key: Key('session-notes-full-${session.id}'),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.groupCoordinationYourResponseTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _RsvpButton(
                  label: context.l10n.groupCoordinationRsvpIn,
                  isSelected: currentRsvp?.response == 'in',
                  onPressed: currentUserId == null || isUpdating
                      ? null
                      : () => onRsvp(session.id, 'in'),
                ),
                _RsvpButton(
                  label: context.l10n.groupCoordinationRsvpMaybe,
                  isSelected: currentRsvp?.response == 'maybe',
                  onPressed: currentUserId == null || isUpdating
                      ? null
                      : () => onRsvp(session.id, 'maybe'),
                ),
                _RsvpButton(
                  label: context.l10n.groupCoordinationRsvpOut,
                  isSelected: currentRsvp?.response == 'out',
                  onPressed: currentUserId == null || isUpdating
                      ? null
                      : () => onRsvp(session.id, 'out'),
                ),
              ],
            ),
            if (isUpdating) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.groupCoordinationRsvpUpdating,
                style: const TextStyle(color: AppColors.textTertiary),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.groupCoordinationResponsesTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: session.rsvps.isEmpty
                  ? Text(
                      context.l10n.groupCoordinationResponsesEmpty,
                      style: const TextStyle(color: AppColors.textSecondary),
                    )
                  : ListView(
                      children: [
                        for (final entry in ['in', 'maybe', 'out']) ...[
                          if (groupedResponses[entry]!.isNotEmpty)
                            _SessionResponseSection(
                              title: _rsvpLabel(context, entry),
                              entries: groupedResponses[entry]!,
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionResponseSection extends StatelessWidget {
  const _SessionResponseSection({required this.title, required this.entries});

  final String title;
  final List<SessionRsvp> entries;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final entry in entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                entry.displayName,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                _timeAgo(context, entry.updatedAt),
                style: const TextStyle(color: AppColors.textTertiary),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.activity});

  final List<GroupActivityEvent> activity;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.groupCoordinationActivityTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (activity.isEmpty)
            Text(
              context.l10n.groupCoordinationActivityEmpty,
              style: const TextStyle(color: AppColors.textSecondary),
            )
          else
            for (final event in activity)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.bolt_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  _activityLabel(context, event),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  _timeAgo(context, event.createdAt),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        GlassButton(
          variant: GlassButtonVariant.secondary,
          onPressed: onAction,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppChip.surface(
      label: label,
      icon: icon,
      backgroundColor: AppColors.glassSurfaceLight,
      textColor: AppColors.textPrimary,
      iconColor: AppColors.primary,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppChip.surface(
      label: label,
      backgroundColor: AppColors.glassSurface,
    );
  }
}

class _SessionRsvpCounts {
  const _SessionRsvpCounts({
    required this.inCount,
    required this.maybeCount,
    required this.outCount,
  });

  final int inCount;
  final int maybeCount;
  final int outCount;
}

_SessionRsvpCounts _countSessionRsvps(List<SessionRsvp> rsvps) {
  var inCount = 0;
  var maybeCount = 0;
  var outCount = 0;
  for (final rsvp in rsvps) {
    switch (rsvp.response) {
      case 'in':
        inCount++;
        break;
      case 'maybe':
        maybeCount++;
        break;
      case 'out':
        outCount++;
        break;
    }
  }
  return _SessionRsvpCounts(
    inCount: inCount,
    maybeCount: maybeCount,
    outCount: outCount,
  );
}

GroupSession? _findSessionById(List<GroupSession> sessions, String sessionId) {
  for (final session in sessions) {
    if (session.id == sessionId) {
      return session;
    }
  }
  return null;
}

SessionRsvp? _findCurrentRsvp(List<SessionRsvp> rsvps, String? currentUserId) {
  if (currentUserId == null) return null;
  for (final rsvp in rsvps) {
    if (rsvp.userId == currentUserId) {
      return rsvp;
    }
  }
  return null;
}

class _SessionRsvpCountChip extends StatelessWidget {
  const _SessionRsvpCountChip({
    super.key,
    required this.icon,
    required this.count,
  });

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return AppChip.surface(
      label: count.toString(),
      icon: icon,
      compact: true,
      backgroundColor: AppColors.glassSurface,
      textColor: AppColors.textSecondary,
      iconColor: AppColors.primary,
    );
  }
}

class _RsvpButton extends StatelessWidget {
  const _RsvpButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onPressed == null ? null : (_) => onPressed?.call(),
      selectedColor: AppColors.primary.withValues(alpha: 0.24),
      backgroundColor: AppColors.glassSurface,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
      ),
      side: const BorderSide(color: AppColors.glassBorder),
    );
  }
}

class _WindowEditorSheet extends StatefulWidget {
  const _WindowEditorSheet({
    required this.onSave,
    this.onDelete,
    this.initialWindow,
  });

  final Future<void> Function(DateTime startsAt, DateTime endsAt) onSave;
  final Future<void> Function()? onDelete;
  final ScheduledReadyWindow? initialWindow;

  @override
  State<_WindowEditorSheet> createState() => _WindowEditorSheetState();
}

class _WindowEditorSheetState extends State<_WindowEditorSheet> {
  late DateTime _startsAt;
  late DateTime _endsAt;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startsAt =
        widget.initialWindow?.startsAt.toLocal() ??
        DateTime.now().add(const Duration(hours: 2));
    _endsAt =
        widget.initialWindow?.endsAt.toLocal() ??
        _startsAt.add(const Duration(hours: 2));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: GlassCard(
        margin: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initialWindow == null
                  ? l10n.groupCoordinationAddWindowTitle
                  : l10n.groupCoordinationEditWindowTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _DateTimeField(
              label: l10n.groupCoordinationStartsAt,
              value: _startsAt,
              onChanged: (value) => setState(() => _startsAt = value),
            ),
            const SizedBox(height: AppSpacing.md),
            _DateTimeField(
              label: l10n.groupCoordinationEndsAt,
              value: _endsAt,
              onChanged: (value) => setState(() => _endsAt = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                if (widget.onDelete != null)
                  Expanded(
                    child: GlassButton(
                      variant: GlassButtonVariant.ghost,
                      onPressed: _isSaving
                          ? null
                          : () async {
                              final confirmed = await showAppConfirmationDialog(
                                context,
                                title: context
                                    .l10n
                                    .groupCoordinationDeleteWindowConfirmTitle,
                                message: context
                                    .l10n
                                    .groupCoordinationDeleteWindowConfirmMessage,
                                confirmLabel: context.l10n.commonDelete,
                                cancelLabel: context.l10n.commonCancel,
                                variant: AppConfirmationVariant.destructive,
                              );
                              if (!confirmed || !context.mounted) return;
                              final navigator = Navigator.of(context);
                              final l10n = context.l10n;
                              setState(() => _isSaving = true);
                              try {
                                await widget.onDelete!.call();
                                if (!mounted) return;
                                navigator.pop();
                              } catch (error) {
                                if (!mounted) return;
                                AppToast.error(
                                  navigator.context,
                                  ApiError.userMessage(error, l10n),
                                );
                              } finally {
                                if (mounted) setState(() => _isSaving = false);
                              }
                            },
                      child: Text(l10n.commonDelete),
                    ),
                  ),
                if (widget.onDelete != null)
                  const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: GlassButton(
                    onPressed: _isSaving || !_endsAt.isAfter(_startsAt)
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);
                            final l10n = context.l10n;
                            setState(() => _isSaving = true);
                            try {
                              await widget.onSave(
                                _startsAt.toUtc(),
                                _endsAt.toUtc(),
                              );
                              if (!mounted) return;
                              navigator.pop();
                            } catch (error) {
                              if (!mounted) return;
                              AppToast.error(
                                navigator.context,
                                ApiError.userMessage(error, l10n),
                              );
                            } finally {
                              if (mounted) setState(() => _isSaving = false);
                            }
                          },
                    isLoading: _isSaving,
                    child: Text(l10n.commonSave),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionEditorSheet extends StatefulWidget {
  const _SessionEditorSheet({required this.onSave, this.initialSession});

  final Future<void> Function(
    String? title,
    String? game,
    String? notes,
    DateTime startsAt,
    String? status,
  )
  onSave;
  final GroupSession? initialSession;

  @override
  State<_SessionEditorSheet> createState() => _SessionEditorSheetState();
}

class _SessionEditorSheetState extends State<_SessionEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _gameController;
  late final TextEditingController _notesController;
  late DateTime _startsAt;
  String? _status;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialSession?.title,
    );
    _gameController = TextEditingController(text: widget.initialSession?.game);
    _notesController = TextEditingController(
      text: widget.initialSession?.notes,
    );
    _startsAt =
        widget.initialSession?.startsAt.toLocal() ??
        DateTime.now().add(const Duration(days: 1, hours: 2));
    _status = widget.initialSession?.status ?? 'proposed';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _gameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: GlassCard(
        margin: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initialSession == null
                  ? l10n.groupCoordinationAddSessionTitle
                  : l10n.groupCoordinationEditSessionTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassInput(
              controller: _titleController,
              label: l10n.groupCoordinationFieldTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            GlassInput(
              controller: _gameController,
              label: l10n.groupCoordinationFieldGame,
            ),
            const SizedBox(height: AppSpacing.md),
            GlassInput(
              controller: _notesController,
              label: l10n.groupCoordinationFieldNotes,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            _DateTimeField(
              label: l10n.groupCoordinationStartsAt,
              value: _startsAt,
              onChanged: (value) => setState(() => _startsAt = value),
            ),
            if (widget.initialSession != null) ...[
              const SizedBox(height: AppSpacing.md),
              Builder(
                builder: (context) {
                  final statusOptions = <({String value, String label})>[
                    (
                      value: 'proposed',
                      label: l10n.groupCoordinationStatusProposed,
                    ),
                    (
                      value: 'confirmed',
                      label: l10n.groupCoordinationStatusConfirmed,
                    ),
                    (
                      value: 'cancelled',
                      label: l10n.groupCoordinationStatusCancelled,
                    ),
                  ];

                  return AppDropdownSelector<String>.field(
                    value: _status ?? statusOptions.first.value,
                    labelText: l10n.groupCoordinationFieldStatus,
                    options: statusOptions
                        .map(
                          (option) => AppDropdownOption(
                            value: option.value,
                            label: option.label,
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _status = value);
                    },
                  );
                },
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            GlassButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      final shouldConfirmCancellation =
                          widget.initialSession != null &&
                          widget.initialSession!.status != 'cancelled' &&
                          _status == 'cancelled';
                      if (shouldConfirmCancellation) {
                        final confirmed = await showAppConfirmationDialog(
                          context,
                          title: context
                              .l10n
                              .groupCoordinationCancelSessionConfirmTitle,
                          message: context
                              .l10n
                              .groupCoordinationCancelSessionConfirmMessage,
                          confirmLabel: context
                              .l10n
                              .groupCoordinationCancelSessionConfirmAction,
                          cancelLabel: context.l10n.commonCancel,
                          variant: AppConfirmationVariant.destructive,
                        );
                        if (!confirmed || !context.mounted) return;
                      }
                      final navigator = Navigator.of(context);
                      final l10n = context.l10n;
                      setState(() => _isSaving = true);
                      try {
                        await widget.onSave(
                          _titleController.text.trim().isEmpty
                              ? null
                              : _titleController.text.trim(),
                          _gameController.text.trim().isEmpty
                              ? null
                              : _gameController.text.trim(),
                          _notesController.text.trim().isEmpty
                              ? null
                              : _notesController.text.trim(),
                          _startsAt.toUtc(),
                          _status,
                        );
                        if (!mounted) return;
                        navigator.pop();
                      } catch (error) {
                        if (!mounted) return;
                        AppToast.error(
                          navigator.context,
                          ApiError.userMessage(error, l10n),
                        );
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
              isLoading: _isSaving,
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
          switchToInputEntryModeIcon: const Icon(Icons.keyboard_alt_outlined),
          switchToCalendarEntryModeIcon: const Icon(
            Icons.calendar_month_outlined,
          ),
          builder: _pickerThemeBuilder,
        );
        if (pickedDate == null || !context.mounted) return;
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
          switchToInputEntryModeIcon: const Icon(Icons.keyboard_alt_outlined),
          switchToTimerEntryModeIcon: const Icon(Icons.schedule_outlined),
          builder: _pickerThemeBuilder,
        );
        if (pickedTime == null) return;
        if (!context.mounted) return;
        onChanged(
          DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          ),
        );
        ProviderScope.containerOf(
          context,
          listen: false,
        ).read(appHapticsProvider).selection();
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          _formatDateTime(context, value),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

Widget _pickerThemeBuilder(BuildContext context, Widget? child) {
  final theme = Theme.of(context);
  return Theme(
    data: theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(onPrimary: AppColors.background),
    ),
    child: child ?? const SizedBox.shrink(),
  );
}

String _formatDayHeading(BuildContext context, DateTime date) {
  final localDate = date.toLocal();
  final weekday = switch (localDate.weekday) {
    DateTime.monday => context.l10n.dayMonShort,
    DateTime.tuesday => context.l10n.dayTueShort,
    DateTime.wednesday => context.l10n.dayWedShort,
    DateTime.thursday => context.l10n.dayThuShort,
    DateTime.friday => context.l10n.dayFriShort,
    DateTime.saturday => context.l10n.daySatShort,
    DateTime.sunday => context.l10n.daySunShort,
    _ => '',
  };
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  return '$weekday, ${DateFormat.MMMd(localeTag).format(localDate)}';
}

String _formatDateTime(BuildContext context, DateTime dateTime) {
  final local = dateTime.toLocal();
  final material = MaterialLocalizations.of(context);
  return '${material.formatMediumDate(local)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

String _formatTimeRange(
  BuildContext context,
  DateTime startsAt,
  DateTime endsAt,
) {
  final material = MaterialLocalizations.of(context);
  return '${material.formatTimeOfDay(TimeOfDay.fromDateTime(startsAt.toLocal()))} - ${material.formatTimeOfDay(TimeOfDay.fromDateTime(endsAt.toLocal()))}';
}

String _statusLabel(BuildContext context, String status) {
  return switch (status) {
    'confirmed' => context.l10n.groupCoordinationStatusConfirmed,
    'cancelled' => context.l10n.groupCoordinationStatusCancelled,
    _ => context.l10n.groupCoordinationStatusProposed,
  };
}

String _rsvpLabel(BuildContext context, String response) {
  return switch (response) {
    'in' => context.l10n.groupCoordinationRsvpIn,
    'out' => context.l10n.groupCoordinationRsvpOut,
    _ => context.l10n.groupCoordinationRsvpMaybe,
  };
}

String _activityLabel(BuildContext context, GroupActivityEvent event) {
  return switch (event.type) {
    'scheduled_ready_updated' =>
      context.l10n.groupCoordinationActivityScheduledReadyUpdated(
        event.actorDisplayName,
      ),
    'scheduled_ready_deleted' =>
      context.l10n.groupCoordinationActivityScheduledReadyDeleted(
        event.actorDisplayName,
      ),
    'session_proposed' => context.l10n.groupCoordinationActivitySessionProposed(
      event.actorDisplayName,
    ),
    'session_updated' => context.l10n.groupCoordinationActivitySessionUpdated(
      event.actorDisplayName,
    ),
    'session_deleted' => context.l10n.groupCoordinationActivitySessionDeleted(
      event.actorDisplayName,
    ),
    'session_rsvp_updated' =>
      context.l10n.groupCoordinationActivitySessionRsvpUpdated(
        event.actorDisplayName,
      ),
    _ => event.message,
  };
}

String _timeAgo(BuildContext context, DateTime timestamp) {
  final diff = DateTime.now().difference(timestamp.toLocal());
  if (diff.inDays >= 1) {
    return context.l10n.groupSettingsTimeAgoDays(diff.inDays);
  }
  if (diff.inHours >= 1) {
    return context.l10n.groupSettingsTimeAgoHours(diff.inHours);
  }
  final minutes = diff.inMinutes <= 0 ? 1 : diff.inMinutes;
  return context.l10n.groupSettingsTimeAgoMinutes(minutes);
}
