import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/api_error.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/desktop_content_region.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../../../../shared/widgets/loading_indicator.dart';
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

class _GroupCoordinationScreenState extends ConsumerState<GroupCoordinationScreen> {
  static const _calendarRangeDays = 7;

  late DateTime _rangeStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _rangeStart = DateTime(now.year, now.month, now.day);
  }

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
            final currentUserId = ref.watch(authNotifierProvider).value?.maybeWhen(
              authenticated: (user) => user.id,
              orElse: () => null,
            );
            final currentUserRole = detailAsync.value?.currentUserRole;
            return DesktopContentRegion(
              width: DesktopContentWidth.reading,
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.backgroundLight,
                onRefresh: () => ref
                    .read(
                      groupCoordinationNotifierProvider(widget.groupId).notifier,
                    )
                    .refresh(),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    _SummaryCard(
                      windowCount: coordination.windows.length,
                      sessionCount: coordination.sessions.length,
                      activityCount: coordination.activity.length,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _CalendarSection(
                      windows: coordination.windows,
                      rangeStart: _rangeStart,
                      rangeDays: _calendarRangeDays,
                      currentUserId: currentUserId,
                      currentUserRole: currentUserRole,
                      onPreviousRange: () => setState(() {
                        _rangeStart = _rangeStart.subtract(
                          const Duration(days: _calendarRangeDays),
                        );
                      }),
                      onNextRange: () => setState(() {
                        _rangeStart = _rangeStart.add(
                          const Duration(days: _calendarRangeDays),
                        );
                      }),
                      onAdd: () => _showWindowEditor(context, ref),
                      onEdit: (window) => _showWindowEditor(
                        context,
                        ref,
                        initialWindow: window,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SessionsSection(
                      sessions: coordination.sessions,
                      currentUserId: currentUserId,
                      currentUserRole: currentUserRole,
                      pendingRsvpSessionIds:
                          coordination.pendingRsvpSessionIds,
                      onAdd: () => _showSessionEditor(context, ref),
                      onEdit: (session) => _showSessionEditor(
                        context,
                        ref,
                        initialSession: session,
                      ),
                      onRsvp: (sessionId, response) => ref
                          .read(
                            groupCoordinationNotifierProvider(widget.groupId)
                                .notifier,
                          )
                          .rsvpToSession(sessionId, response),
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
            },
            onDelete: initialWindow == null
                ? null
                : () => ref
                    .read(
                      groupCoordinationNotifierProvider(widget.groupId).notifier,
                    )
                    .deleteScheduledReady(initialWindow.id),
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
            },
          ),
        );
      },
    );
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
                label: context.l10n.groupCoordinationSessionsCount(sessionCount),
              ),
              _SummaryChip(
                icon: Icons.bolt_outlined,
                label: context.l10n.groupCoordinationActivityCount(activityCount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarSection extends StatelessWidget {
  const _CalendarSection({
    required this.windows,
    required this.rangeStart,
    required this.rangeDays,
    required this.currentUserId,
    required this.currentUserRole,
    required this.onPreviousRange,
    required this.onNextRange,
    required this.onAdd,
    required this.onEdit,
  });

  final List<ScheduledReadyWindow> windows;
  final DateTime rangeStart;
  final int rangeDays;
  final String? currentUserId;
  final String? currentUserRole;
  final VoidCallback onPreviousRange;
  final VoidCallback onNextRange;
  final VoidCallback onAdd;
  final ValueChanged<ScheduledReadyWindow> onEdit;

  @override
  Widget build(BuildContext context) {
    final visibleWindows = _windowsInRange(windows);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: context.l10n.groupCoordinationCalendarTitle,
            actionLabel: context.l10n.groupCoordinationCalendarAdd,
            onAction: onAdd,
          ),
          const SizedBox(height: AppSpacing.sm),
          _CalendarRangeHeader(
            label: _formatRangeLabel(context),
            onPrevious: onPreviousRange,
            onNext: onNextRange,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (visibleWindows.isEmpty)
            Text(
              windows.isEmpty
                  ? context.l10n.groupCoordinationCalendarEmpty
                  : context.l10n.groupCoordinationCalendarEmptyRange,
              style: const TextStyle(color: AppColors.textSecondary),
            )
          else
            ..._groupWindowsByDay(context, visibleWindows),
        ],
      ),
    );
  }

  List<ScheduledReadyWindow> _windowsInRange(List<ScheduledReadyWindow> all) {
    final end = rangeStart.add(Duration(days: rangeDays));
    return all.where((window) {
      final startsAt = window.startsAt.toLocal();
      final endsAt = window.endsAt.toLocal();
      return startsAt.isBefore(end) && endsAt.isAfter(rangeStart);
    }).toList();
  }

  List<Widget> _groupWindowsByDay(
    BuildContext context,
    List<ScheduledReadyWindow> windows,
  ) {
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
      for (final date in dates) ...[
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
          child: Text(
            _formatDayHeading(context, date),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (final window in grouped[date]!)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    window.displayName,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
                if (window.userId == currentUserId) ...[
                  const SizedBox(width: AppSpacing.xs),
                  _Pill(label: context.l10n.groupCoordinationOwnedByYou),
                ],
              ],
            ),
            subtitle: Text(
              _formatTimeRange(context, window.startsAt, window.endsAt),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            trailing: _canEditWindow(window)
                ? IconButton(
                    onPressed: () => onEdit(window),
                    tooltip: context.l10n.groupCoordinationEditWindowTitle,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.textSecondary,
                    ),
                  )
                : null,
          ),
      ],
    ];
  }

  bool _canEditWindow(ScheduledReadyWindow window) {
    if (window.userId == currentUserId) {
      return true;
    }
    return currentUserRole == 'owner' || currentUserRole == 'admin';
  }

  String _formatRangeLabel(BuildContext context) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    if (rangeStart == todayStart) {
      return context.l10n.groupCoordinationCalendarThisWeek;
    }
    final end = rangeStart.add(Duration(days: rangeDays - 1));
    final material = MaterialLocalizations.of(context);
    return context.l10n.groupCoordinationCalendarRangeLabel(
      material.formatMediumDate(rangeStart),
      material.formatMediumDate(end),
    );
  }
}

class _SessionsSection extends StatelessWidget {
  const _SessionsSection({
    required this.sessions,
    required this.currentUserId,
    required this.currentUserRole,
    required this.pendingRsvpSessionIds,
    required this.onAdd,
    required this.onEdit,
    required this.onRsvp,
  });

  final List<GroupSession> sessions;
  final String? currentUserId;
  final String? currentUserRole;
  final Set<String> pendingRsvpSessionIds;
  final VoidCallback onAdd;
  final ValueChanged<GroupSession> onEdit;
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
                  onEdit: () => onEdit(session),
                  onRsvp: onRsvp,
                ),
              ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.currentUserId,
    required this.currentUserRole,
    required this.isUpdatingRsvp,
    required this.onEdit,
    required this.onRsvp,
  });

  final GroupSession session;
  final String? currentUserId;
  final String? currentUserRole;
  final bool isUpdatingRsvp;
  final VoidCallback onEdit;
  final Future<void> Function(String sessionId, String response) onRsvp;

  @override
  Widget build(BuildContext context) {
    SessionRsvp? currentRsvp;
    for (final item in session.rsvps) {
      if (item.userId == currentUserId) {
        currentRsvp = item;
        break;
      }
    }

    return Container(
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
                      session.title ?? session.game ?? context.l10n.groupCoordinationUntitledSession,
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
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _formatDateTime(context, session.startsAt),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.l10n.groupCoordinationProposedBy(session.proposedByDisplayName),
                      style: const TextStyle(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              if (_canEditSession())
                IconButton(
                  onPressed: onEdit,
                  tooltip: context.l10n.groupCoordinationEditSessionTitle,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          if (session.notes != null && session.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              session.notes!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _Pill(label: _statusLabel(context, session.status)),
              ...session.rsvps.map(
                (rsvp) => _Pill(
                  label:
                      '${rsvp.displayName}: ${_rsvpLabel(context, rsvp.response)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _RsvpButton(
                label: context.l10n.groupCoordinationRsvpIn,
                isSelected: currentRsvp?.response == 'in',
                onPressed: currentUserId == null || isUpdatingRsvp
                    ? null
                    : () => onRsvp(session.id, 'in'),
              ),
              _RsvpButton(
                label: context.l10n.groupCoordinationRsvpMaybe,
                isSelected: currentRsvp?.response == 'maybe',
                onPressed: currentUserId == null || isUpdatingRsvp
                    ? null
                    : () => onRsvp(session.id, 'maybe'),
              ),
              _RsvpButton(
                label: context.l10n.groupCoordinationRsvpOut,
                isSelected: currentRsvp?.response == 'out',
                onPressed: currentUserId == null || isUpdatingRsvp
                    ? null
                    : () => onRsvp(session.id, 'out'),
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
    );
  }

  bool _canEditSession() {
    if (session.proposedBy == currentUserId) {
      return true;
    }
    return currentUserRole == 'owner' || currentUserRole == 'admin';
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

class _CalendarRangeHeader extends StatelessWidget {
  const _CalendarRangeHeader({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          tooltip: context.l10n.groupCoordinationCalendarPreviousRange,
          icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: context.l10n.groupCoordinationCalendarNextRange,
          icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.glassSurfaceLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
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
    _startsAt = widget.initialWindow?.startsAt.toLocal() ??
        DateTime.now().add(const Duration(hours: 2));
    _endsAt = widget.initialWindow?.endsAt.toLocal() ??
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
                if (widget.onDelete != null) const SizedBox(width: AppSpacing.sm),
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
  const _SessionEditorSheet({
    required this.onSave,
    this.initialSession,
  });

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
    _titleController = TextEditingController(text: widget.initialSession?.title);
    _gameController = TextEditingController(text: widget.initialSession?.game);
    _notesController = TextEditingController(text: widget.initialSession?.notes);
    _startsAt = widget.initialSession?.startsAt.toLocal() ??
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
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: l10n.groupCoordinationFieldStatus,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'proposed',
                    child: Text(l10n.groupCoordinationStatusProposed),
                  ),
                  DropdownMenuItem(
                    value: 'confirmed',
                    child: Text(l10n.groupCoordinationStatusConfirmed),
                  ),
                  DropdownMenuItem(
                    value: 'cancelled',
                    child: Text(l10n.groupCoordinationStatusCancelled),
                  ),
                ],
                onChanged: (value) => setState(() => _status = value),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            GlassButton(
              onPressed: _isSaving
                  ? null
                  : () async {
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
        onChanged(
          DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          ),
        );
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
      colorScheme: theme.colorScheme.copyWith(
        onPrimary: AppColors.background,
      ),
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
  final material = MaterialLocalizations.of(context);
  return '$weekday, ${material.formatMediumDate(localDate)}';
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
    'scheduled_ready_updated' => context.l10n
        .groupCoordinationActivityScheduledReadyUpdated(event.actorDisplayName),
    'scheduled_ready_deleted' => context.l10n
        .groupCoordinationActivityScheduledReadyDeleted(event.actorDisplayName),
    'session_proposed' => context.l10n
        .groupCoordinationActivitySessionProposed(event.actorDisplayName),
    'session_updated' => context.l10n
        .groupCoordinationActivitySessionUpdated(event.actorDisplayName),
    'session_rsvp_updated' => context.l10n
        .groupCoordinationActivitySessionRsvpUpdated(event.actorDisplayName),
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
