import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/providers/presence_provider.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../domain/coordination_model.dart';
import '../../domain/group_model.dart';
import '../providers/group_coordination_provider.dart';

class GroupCard extends ConsumerWidget {
  const GroupCard({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final presence = ref.watch(presenceNotifierProvider);
    final groupPresence = presence[group.id] ?? {};
    final readyCount = groupPresence.values.where((m) => m.ready).length;

    final coordinationAsync =
        ref.watch(groupCoordinationNotifierProvider(group.id));

    GroupSession? nextSession;
    ScheduledReadyWindow? nextWindow;
    coordinationAsync.whenData((state) {
      nextSession = _nextSession(state);
      nextWindow = _nextWindow(state);
    });

    final hasActivity =
        readyCount > 0 || nextSession != null || nextWindow != null;

    return GlassCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.goNamed(
        RouteNames.groupDetail,
        pathParameters: {'id': group.id},
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: UserAvatar(
              imageUrl: group.avatarUrl,
              displayName: group.name,
              size: 56,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (group.description != null &&
                    group.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    group.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _MetaTag(
                      icon: Icons.people_outline,
                      label: l10n.joinGroupMembers(group.memberCount),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _MetaTag(
                      icon: group.isDiscoverable
                          ? Icons.public
                          : Icons.lock_outline,
                      label: group.isDiscoverable
                          ? l10n.groupVisibilityPublic
                          : l10n.groupVisibilityPrivate,
                    ),
                    if (readyCount > 0) ...[
                      const Spacer(),
                      _ReadyBadge(count: readyCount),
                    ],
                  ],
                ),
                if (hasActivity && (nextSession != null || nextWindow != null)) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _ActivitySection(
                    nextSession: nextSession,
                    nextWindow: nextWindow,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  GroupSession? _nextSession(GroupCoordinationState state) {
    final now = DateTime.now();
    GroupSession? best;
    DateTime? bestTime;
    for (final s in state.sessions) {
      if (s.status == 'cancelled') continue;
      final local = s.startsAt.toLocal();
      if (local.isBefore(now)) continue;
      if (bestTime == null || local.isBefore(bestTime)) {
        bestTime = local;
        best = s;
      }
    }
    return best;
  }

  ScheduledReadyWindow? _nextWindow(GroupCoordinationState state) {
    final now = DateTime.now();
    ScheduledReadyWindow? best;
    DateTime? bestTime;
    for (final w in state.windows) {
      final local = w.startsAt.toLocal();
      if (local.isBefore(now)) continue;
      if (bestTime == null || local.isBefore(bestTime)) {
        bestTime = local;
        best = w;
      }
    }
    return best;
  }
}

class _ReadyBadge extends StatelessWidget {
  const _ReadyBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            context.l10n.groupCardReadyNow(count),
            style: TextStyle(
              color: AppColors.success.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({this.nextSession, this.nextWindow});

  final GroupSession? nextSession;
  final ScheduledReadyWindow? nextWindow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (nextSession != null) _SessionCard(session: nextSession!),
        if (nextSession != null && nextWindow != null)
          const SizedBox(height: 6),
        if (nextWindow != null) _WindowCard(window: nextWindow!),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final GroupSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = session.title ?? l10n.groupCardSession;
    final titleWithGame = session.game != null && session.title != null
        ? '$title · ${session.game}'
        : session.game != null
            ? session.game!
            : title;

    return _EventCard(
      color: AppColors.primary,
      icon: Icons.sports_esports_outlined,
      title: titleWithGame,
      subtitle: _formatSubtitle(context),
    );
  }

  String _formatSubtitle(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final local = session.startsAt.toLocal();
    final time = material.formatTimeOfDay(TimeOfDay.fromDateTime(local));
    final prefix = _relativePrefix(context, local);
    return '$prefix · $time';
  }
}

class _WindowCard extends StatelessWidget {
  const _WindowCard({required this.window});

  final ScheduledReadyWindow window;

  @override
  Widget build(BuildContext context) {
    return _EventCard(
      color: AppColors.warning,
      icon: Icons.schedule_outlined,
      title: window.displayName,
      subtitle: _formatSubtitle(context),
    );
  }

  String _formatSubtitle(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final start = window.startsAt.toLocal();
    final end = window.endsAt.toLocal();
    final startTime =
        material.formatTimeOfDay(TimeOfDay.fromDateTime(start));
    final endTime =
        material.formatTimeOfDay(TimeOfDay.fromDateTime(end));
    final prefix = _relativePrefix(context, start);
    return '$prefix · $startTime – $endTime';
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.55),
                    fontSize: 11,
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

String _relativePrefix(BuildContext context, DateTime local) {
  final l10n = context.l10n;
  final now = DateTime.now();
  final diff = local.difference(now);

  if (diff.inMinutes < 60) {
    return l10n.groupCardUpcomingMinutes(diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return l10n.groupCardUpcomingHours(diff.inHours);
  }
  if (diff.inDays <= 1 && local.day != now.day) {
    return l10n.groupCardTomorrow;
  }
  return MaterialLocalizations.of(context).formatShortDate(local);
}

class _MetaTag extends StatelessWidget {
  const _MetaTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
