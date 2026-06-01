import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/networking/websocket_client.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../widgets/status_indicator.dart';

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
      readyExpiresAt:
          clearReadyExpiresAt ? null : (readyExpiresAt ?? this.readyExpiresAt),
    );
  }
}

class PresenceNotifier
    extends Notifier<Map<String, Map<String, MemberPresenceState>>> {
  StreamSubscription<dynamic>? _subscription;
  final _expiryTimers = <String, Timer>{};

  @override
  Map<String, Map<String, MemberPresenceState>> build() {
    _subscription?.cancel();
    _cancelAllExpiryTimers();
    ref.onDispose(() {
      _subscription?.cancel();
      _cancelAllExpiryTimers();
    });

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
    return <String, Map<String, MemberPresenceState>>{};
  }

  void toggleReady({required String groupId, required bool ready}) {
    final authState = ref.read(authNotifierProvider).valueOrNull;
    final userId = authState?.maybeWhen(
      authenticated: (user) => user.id,
      orElse: () => null,
    );
    if (userId != null) {
      if (ready) {
        final expiresAt =
            DateTime.now().add(const Duration(hours: 8)).millisecondsSinceEpoch ~/
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

    ref.read(websocketClientProvider).sendReadyToggle(
          groupId: groupId,
          ready: ready,
        );
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
          update: (_) => const MemberPresenceState(connection: 'offline'),
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
      case 'ready_changed':
        _applyReadyChanged(event);
        break;
      default:
        break;
    }
  }

  void _applySnapshot(Map event) {
    final groups = event['groups'];
    if (groups is! List) return;

    final next = <String, Map<String, MemberPresenceState>>{
      for (final entry in state.entries)
        entry.key: Map<String, MemberPresenceState>.from(entry.value),
    };

    for (final group in groups) {
      if (group is! Map) continue;
      final groupId = group['group_id'] as String?;
      if (groupId == null) continue;

      final members = <String, MemberPresenceState>{};
      final memberList = group['members'];
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
      }
      next[groupId] = members;
    }

    state = next;
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
    final ready = rawMember['ready'] == true;
    final readyExpiresAt = rawMember['ready_expires_at'] as String?;
    final readyStillValid = ready && !_isExpired(readyExpiresAt);

    return MemberPresenceState(
      connection: rawMember['connection'] as String? ?? 'offline',
      ready: readyStillValid,
      readySince: readyStillValid ? rawMember['ready_since'] as String? : null,
      readyExpiresAt: readyStillValid ? readyExpiresAt : null,
    );
  }

  void _updateMember({
    required String? groupId,
    required String? userId,
    required MemberPresenceState Function(MemberPresenceState current) update,
  }) {
    if (groupId == null || userId == null) return;

    final next = <String, Map<String, MemberPresenceState>>{
      for (final entry in state.entries)
        entry.key: Map<String, MemberPresenceState>.from(entry.value),
    };
    final groupMembers = next[groupId] ?? <String, MemberPresenceState>{};
    final current = groupMembers[userId] ?? const MemberPresenceState();
    groupMembers[userId] = update(current);
    next[groupId] = groupMembers;
    state = next;
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
  if (member == null || member.connection == 'offline') {
    return UserStatus.offline;
  }
  if (member.connection == 'away') {
    return UserStatus.away;
  }
  if (member.ready) {
    return UserStatus.ready;
  }
  return UserStatus.online;
}

final presenceNotifierProvider = NotifierProvider<
    PresenceNotifier, Map<String, Map<String, MemberPresenceState>>>(
  PresenceNotifier.new,
);

final groupMemberStatusProvider = Provider.family<UserStatus, GroupUserPresenceKey>((
  ref,
  key,
) {
  final presence = ref.watch(presenceNotifierProvider);
  return deriveMemberStatus(presence[key.groupId]?[key.userId]);
});

final currentUserReadyProvider = Provider.family<bool, String>((ref, groupId) {
  final presence = ref.watch(presenceNotifierProvider);
  final authState = ref.watch(authNotifierProvider).valueOrNull;
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
