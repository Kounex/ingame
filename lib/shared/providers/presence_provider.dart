import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/networking/websocket_client.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../widgets/status_indicator.dart';

typedef GroupUserPresenceKey = ({String groupId, String userId});

class PresenceNotifier extends Notifier<Map<String, Map<String, UserStatus>>> {
  StreamSubscription<dynamic>? _subscription;

  @override
  Map<String, Map<String, UserStatus>> build() {
    _subscription?.cancel();
    ref.onDispose(() => _subscription?.cancel());

    final authState = ref.watch(authNotifierProvider).valueOrNull;
    final isAuthenticated = authState?.maybeWhen(
          authenticated: (_) => true,
          orElse: () => false,
        ) ??
        false;

    if (!isAuthenticated) {
      return {};
    }

    final wsClient = ref.watch(websocketClientProvider);
    _subscription = wsClient.events.listen(_handleEvent);
    return <String, Map<String, UserStatus>>{};
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) return;
    final type = event['type'];

    switch (type) {
      case 'presence_snapshot':
        _applySnapshot(event);
        break;
      case 'user_online':
        _updateUserStatus(
          groupId: event['group_id'] as String?,
          userId: event['user_id'] as String?,
          status: UserStatus.online,
        );
        break;
      case 'user_offline':
        _updateUserStatus(
          groupId: event['group_id'] as String?,
          userId: event['user_id'] as String?,
          status: UserStatus.offline,
        );
        break;
      case 'status_changed':
        _updateUserStatus(
          groupId: event['group_id'] as String?,
          userId: event['user_id'] as String?,
          status: _statusFromWire(event['state'] as String?),
        );
        break;
      default:
        break;
    }
  }

  void _applySnapshot(Map event) {
    final groups = event['groups'];
    if (groups is! List) return;

    final next = <String, Map<String, UserStatus>>{
      for (final entry in state.entries) entry.key: Map<String, UserStatus>.from(entry.value),
    };

    for (final group in groups) {
      if (group is! Map) continue;
      final groupId = group['group_id'] as String?;
      if (groupId == null) continue;

      final statuses = <String, UserStatus>{};
      final statusList = group['statuses'];
      if (statusList is List) {
        for (final rawStatus in statusList) {
          if (rawStatus is! Map) continue;
          final userId = rawStatus['user_id'] as String?;
          if (userId == null) continue;
          statuses[userId] = _statusFromWire(rawStatus['state'] as String?);
        }
      }
      next[groupId] = statuses;
    }

    state = next;
  }

  void _updateUserStatus({
    required String? groupId,
    required String? userId,
    required UserStatus status,
  }) {
    if (groupId == null || userId == null) return;

    final next = <String, Map<String, UserStatus>>{
      for (final entry in state.entries) entry.key: Map<String, UserStatus>.from(entry.value),
    };
    final groupStatuses = next[groupId] ?? <String, UserStatus>{};
    groupStatuses[userId] = status;
    next[groupId] = groupStatuses;
    state = next;
  }

  UserStatus _statusFromWire(String? state) {
    return switch (state) {
      'ready' => UserStatus.ready,
      'online' => UserStatus.online,
      'away' => UserStatus.away,
      _ => UserStatus.offline,
    };
  }
}

final presenceNotifierProvider =
    NotifierProvider<PresenceNotifier, Map<String, Map<String, UserStatus>>>(
      PresenceNotifier.new,
    );

final groupMemberStatusProvider = Provider.family<UserStatus, GroupUserPresenceKey>((
  ref,
  key,
) {
  final presence = ref.watch(presenceNotifierProvider);
  return presence[key.groupId]?[key.userId] ?? UserStatus.offline;
});
