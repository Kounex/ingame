import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/networking/websocket_client.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../widgets/status_indicator.dart';
import 'websocket_provider.dart';

typedef GroupUserPresenceKey = ({String groupId, String userId});

class MemberPresenceState {
  const MemberPresenceState({
    this.connection = 'offline',
    this.ready = false,
    this.readySince,
    this.readyExpiresAt,
  });

  final String connection;
  final bool ready;
  final String? readySince;
  final String? readyExpiresAt;

  MemberPresenceState copyWith({
    String? connection,
    bool? ready,
    String? readySince,
    String? readyExpiresAt,
    bool clearReadySince = false,
    bool clearReadyExpiresAt = false,
  }) {
    return MemberPresenceState(
      connection: connection ?? this.connection,
      ready: ready ?? this.ready,
      readySince: clearReadySince ? null : (readySince ?? this.readySince),
      readyExpiresAt: clearReadyExpiresAt
          ? null
          : (readyExpiresAt ?? this.readyExpiresAt),
    );
  }
}

class PresenceNotifier
    extends Notifier<Map<String, Map<String, MemberPresenceState>>> {
  StreamSubscription<dynamic>? _subscription;
  final _expiryTimers = <String, Timer>{};
  Map<String, Map<String, MemberPresenceState>> _trackedState = const {};

  @override
  Map<String, Map<String, MemberPresenceState>> build() {
    _subscription?.cancel();
    _cancelAllExpiryTimers();
    ref.onDispose(() {
      _subscription?.cancel();
      _cancelAllExpiryTimers();
    });

    final authState = ref.watch(authNotifierProvider).value;
    final isUnauthenticated =
        authState?.maybeWhen(
          unauthenticated: () => true,
          orElse: () => false,
        ) ??
        false;

    if (isUnauthenticated) {
      _trackedState = const {};
      return _trackedState;
    }

    final isAuthenticated =
        authState?.maybeWhen(authenticated: (_) => true, orElse: () => false) ??
        false;

    if (!isAuthenticated) {
      // Auth bootstrap or login `loading` — keep hydrated presence intact.
      return _trackedState;
    }

    final wsClient = ref.watch(websocketClientProvider);
    ref.watch(websocketConnectionStateProvider);
    _subscription = wsClient.events.listen(_handleEvent);
    final cachedSnapshot = wsClient.cachedPresenceSnapshot;
    if (cachedSnapshot != null) {
      _trackedState = _mergeSnapshot(cachedSnapshot, base: _trackedState);
      return _trackedState;
    }
    return _trackedState;
  }

  Map<String, Map<String, MemberPresenceState>> _commitState(
    Map<String, Map<String, MemberPresenceState>> next,
  ) {
    _trackedState = next;
    state = next;
    return next;
  }

  bool toggleReady({required String groupId, required bool ready}) {
    final wsClient = ref.read(websocketClientProvider);
    if (wsClient.connectionState != WebSocketConnectionState.connected) {
      return false;
    }

    final authState = ref.read(authNotifierProvider).value;
    final userId = authState?.maybeWhen(
      authenticated: (user) => user.id,
      orElse: () => null,
    );
    if (userId != null) {
      if (ready) {
        final expiresAt =
            DateTime.now()
                .add(const Duration(hours: 8))
                .millisecondsSinceEpoch ~/
            1000;
        final since = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        _applyReadyChanged({
          'group_id': groupId,
          'user_id': userId,
          'ready': true,
          'ready_since': '$since',
          'ready_expires_at': '$expiresAt',
        });
      } else {
        _applyReadyChanged({
          'group_id': groupId,
          'user_id': userId,
          'ready': false,
        });
      }
    }

    ref
        .read(websocketClientProvider)
        .sendReadyToggle(groupId: groupId, ready: ready);
    return true;
  }

  void handleReadyExpiry({required String groupId, required String userId}) {
    _cancelExpiryTimer(groupId, userId);
    _updateMember(
      groupId: groupId,
      userId: userId,
      update: (current) => current.copyWith(
        ready: false,
        clearReadySince: true,
        clearReadyExpiresAt: true,
      ),
    );
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) return;
    final type = event['type'];

    switch (type) {
      case 'presence_snapshot':
        _applySnapshot(event);
        break;
      case 'user_online':
        _updateMember(
          groupId: event['group_id'] as String?,
          userId: event['user_id'] as String?,
          update: (current) => current.copyWith(connection: 'online'),
        );
        break;
      case 'user_offline':
        _updateMember(
          groupId: event['group_id'] as String?,
          userId: event['user_id'] as String?,
          update: (current) => current.copyWith(connection: 'offline'),
        );
        break;
      case 'connection_changed':
        _updateMember(
          groupId: event['group_id'] as String?,
          userId: event['user_id'] as String?,
          update: (current) => current.copyWith(
            connection: event['connection'] as String? ?? 'online',
          ),
        );
        break;
      case 'status_changed':
        _applyLegacyStatusChanged(event);
        break;
      case 'ready_changed':
        _applyReadyChanged(event);
        break;
      default:
        break;
    }
  }

  void _applySnapshot(Map event) {
    _commitState(_mergeSnapshot(event));
  }

  Map<String, Map<String, MemberPresenceState>> _mergeSnapshot(
    Map event, {
    Map<String, Map<String, MemberPresenceState>>? base,
  }) {
    final groups = event['groups'];
    if (groups is! List) {
      return base ?? _trackedState;
    }

    final next = <String, Map<String, MemberPresenceState>>{
      for (final entry in (base ?? _trackedState).entries)
        entry.key: Map<String, MemberPresenceState>.from(entry.value),
    };

    for (final group in groups) {
      if (group is! Map) continue;
      final groupId = group['group_id'] as String?;
      if (groupId == null) continue;

      final members = <String, MemberPresenceState>{};
      final memberList = group['members'] ?? group['statuses'];
      if (memberList is List) {
        for (final rawMember in memberList) {
          if (rawMember is! Map) continue;
          final userId = rawMember['user_id'] as String?;
          if (userId == null) continue;
          final member = _memberFromWire(rawMember);
          members[userId] = member;
          _scheduleReadyExpiry(
            groupId: groupId,
            userId: userId,
            readyExpiresAt: member.readyExpiresAt,
            ready: member.ready,
          );
        }
      } else {
        final onlineUserIds = group['online_user_ids'];
        if (onlineUserIds is List) {
          for (final rawUserId in onlineUserIds) {
            if (rawUserId is! String) continue;
            members[rawUserId] = const MemberPresenceState(
              connection: 'online',
            );
          }
        }
      }
      next[groupId] = members;
    }

    return next;
  }

  void _applyReadyChanged(Map event) {
    final groupId = event['group_id'] as String?;
    final userId = event['user_id'] as String?;
    if (groupId == null || userId == null) return;

    final ready = event['ready'] == true;
    final readySince = event['ready_since'] as String?;
    final readyExpiresAt = event['ready_expires_at'] as String?;

    _updateMember(
      groupId: groupId,
      userId: userId,
      update: (current) => MemberPresenceState(
        connection: current.connection,
        ready: ready,
        readySince: ready ? readySince : null,
        readyExpiresAt: ready ? readyExpiresAt : null,
      ),
    );

    _scheduleReadyExpiry(
      groupId: groupId,
      userId: userId,
      readyExpiresAt: ready ? readyExpiresAt : null,
      ready: ready,
    );
  }

  MemberPresenceState _memberFromWire(Map rawMember) {
    final wireState =
        rawMember['connection'] as String? ??
        rawMember['state'] as String? ??
        'offline';
    final readyFromState = wireState == 'ready';
    final ready = rawMember['ready'] == true || readyFromState;
    final connection = readyFromState ? 'online' : wireState;
    final readyExpiresAt = rawMember['ready_expires_at'] as String?;
    final readyStillValid = ready && !_isExpired(readyExpiresAt);

    return MemberPresenceState(
      connection: connection,
      ready: readyStillValid,
      readySince: readyStillValid ? rawMember['ready_since'] as String? : null,
      readyExpiresAt: readyStillValid ? readyExpiresAt : null,
    );
  }

  void _applyLegacyStatusChanged(Map event) {
    final groupId = event['group_id'] as String?;
    final userId = event['user_id'] as String?;
    if (groupId == null || userId == null) return;

    final state = event['state'] as String? ?? 'online';
    if (state == 'offline') {
      _updateMember(
        groupId: groupId,
        userId: userId,
        update: (current) => current.copyWith(connection: 'offline'),
      );
      return;
    }

    final ready = state == 'ready';
    _updateMember(
      groupId: groupId,
      userId: userId,
      update: (current) => MemberPresenceState(
        connection: ready ? 'online' : state,
        ready: ready,
        readySince: ready ? event['since'] as String? : null,
        readyExpiresAt: current.readyExpiresAt,
      ),
    );
  }

  void _updateMember({
    required String? groupId,
    required String? userId,
    required MemberPresenceState Function(MemberPresenceState current) update,
  }) {
    if (groupId == null || userId == null) return;

    final next = <String, Map<String, MemberPresenceState>>{
      for (final entry in _trackedState.entries)
        entry.key: Map<String, MemberPresenceState>.from(entry.value),
    };
    final groupMembers = next[groupId] ?? <String, MemberPresenceState>{};
    final current = groupMembers[userId] ?? const MemberPresenceState();
    groupMembers[userId] = update(current);
    next[groupId] = groupMembers;
    _commitState(next);
  }

  void _scheduleReadyExpiry({
    required String groupId,
    required String userId,
    required String? readyExpiresAt,
    required bool ready,
  }) {
    _cancelExpiryTimer(groupId, userId);
    if (!ready || readyExpiresAt == null) return;

    final expiresAtSeconds = int.tryParse(readyExpiresAt);
    if (expiresAtSeconds == null) return;

    final delaySeconds =
        expiresAtSeconds - DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (delaySeconds <= 0) {
      handleReadyExpiry(groupId: groupId, userId: userId);
      return;
    }

    final timerKey = _expiryTimerKey(groupId, userId);
    _expiryTimers[timerKey] = Timer(Duration(seconds: delaySeconds), () {
      handleReadyExpiry(groupId: groupId, userId: userId);
    });
  }

  bool _isExpired(String? readyExpiresAt) {
    if (readyExpiresAt == null) return false;
    final expiresAtSeconds = int.tryParse(readyExpiresAt);
    if (expiresAtSeconds == null) return false;
    return expiresAtSeconds <= DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  String _expiryTimerKey(String groupId, String userId) => '$groupId:$userId';

  void _cancelExpiryTimer(String groupId, String userId) {
    final timer = _expiryTimers.remove(_expiryTimerKey(groupId, userId));
    timer?.cancel();
  }

  void _cancelAllExpiryTimers() {
    for (final timer in _expiryTimers.values) {
      timer.cancel();
    }
    _expiryTimers.clear();
  }
}

UserStatus deriveMemberStatus(MemberPresenceState? member) {
  if (member?.ready ?? false) {
    return UserStatus.ready;
  }
  if (member == null || member.connection == 'offline') {
    return UserStatus.offline;
  }
  if (member.connection == 'away') {
    return UserStatus.away;
  }
  return UserStatus.online;
}

final presenceNotifierProvider =
    NotifierProvider<
      PresenceNotifier,
      Map<String, Map<String, MemberPresenceState>>
    >(PresenceNotifier.new);

final groupMemberStatusProvider =
    Provider.family<UserStatus, GroupUserPresenceKey>((ref, key) {
      final presence = ref.watch(presenceNotifierProvider);
      return deriveMemberStatus(presence[key.groupId]?[key.userId]);
    });

final currentUserReadyProvider = Provider.family<bool, String>((ref, groupId) {
  final presence = ref.watch(presenceNotifierProvider);
  final authState = ref.watch(authNotifierProvider).value;
  final userId = authState?.maybeWhen(
    authenticated: (user) => user.id,
    orElse: () => null,
  );
  if (userId == null) return false;
  final member = presence[groupId]?[userId];
  if (member == null || !member.ready) return false;
  final expiresAt = member.readyExpiresAt;
  if (expiresAt == null) return true;
  final expiresAtSeconds = int.tryParse(expiresAt);
  if (expiresAtSeconds == null) return true;
  return expiresAtSeconds > DateTime.now().millisecondsSinceEpoch ~/ 1000;
});
