import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/networking/websocket_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/groups_repository.dart';
import '../../domain/group_model.dart';

class GroupsNotifier extends AsyncNotifier<List<Group>> {
  StreamSubscription<dynamic>? _subscription;

  @override
  Future<List<Group>> build() async {
    ref.watch(sessionResetSignalProvider);
    _subscription?.cancel();
    ref.onDispose(() => _subscription?.cancel());
    _subscription =
        ref.read(websocketClientProvider).events.listen(_handleEvent);
    final repo = ref.read(groupsRepositoryProvider);
    return await repo.listMyGroups();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(groupsRepositoryProvider);
      return await repo.listMyGroups();
    });
  }

  Future<Group> create({
    required String name,
    String? description,
    bool isDiscoverable = false,
    String joinMode = 'open',
    String? avatarUrl,
  }) async {
    final repo = ref.read(groupsRepositoryProvider);
    final group = await repo.createGroup(
      name: name,
      description: description,
      isDiscoverable: isDiscoverable,
      joinMode: joinMode,
      avatarUrl: avatarUrl,
    );
    await load();
    await _refreshRealtimeMemberships();
    return group;
  }

  Future<Group> joinByInviteCode(String code) async {
    final repo = ref.read(groupsRepositoryProvider);
    final group = await repo.joinByInviteCode(code);
    await load();
    await _refreshRealtimeMemberships();
    return group;
  }

  Future<void> delete(String id) async {
    final repo = ref.read(groupsRepositoryProvider);
    await repo.deleteGroup(id);
    await load();
  }

  Future<void> leaveGroup(String id) async {
    final repo = ref.read(groupsRepositoryProvider);
    await repo.leaveGroup(id);
    await load();
    await _refreshRealtimeMemberships();
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) return;
    final groupId = event['group_id'] as String?;
    if (groupId == null) return;
    final current = state.value;
    if (current == null) return;
    final groupIndex = current.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return;

    switch (event['type']) {
      case 'group_deleted':
        state = AsyncValue.data(
          current.where((g) => g.id != groupId).toList(),
        );
        break;
      case 'group_updated':
        final rawGroup = event['group'];
        if (rawGroup is! Map<String, dynamic>) return;
        try {
          final updated = Group.fromJson(rawGroup);
          final next = [...current];
          next[groupIndex] = updated;
          state = AsyncValue.data(next);
        } catch (_) {}
        break;
      case 'member_joined':
        final next = [...current];
        next[groupIndex] = current[groupIndex].copyWith(
          memberCount: current[groupIndex].memberCount + 1,
        );
        state = AsyncValue.data(next);
        break;
      case 'member_left':
      case 'member_removed':
        final userId = event['user_id'] as String?;
        if (userId == null) return;
        final authState = ref.read(authNotifierProvider).value;
        final currentUserId = authState?.maybeWhen(
          authenticated: (user) => user.id,
          orElse: () => null,
        );
        if (userId == currentUserId) {
          state = AsyncValue.data(
            current.where((g) => g.id != groupId).toList(),
          );
        } else {
          final next = [...current];
          next[groupIndex] = current[groupIndex].copyWith(
            memberCount:
                (current[groupIndex].memberCount - 1).clamp(0, double.maxFinite.toInt()),
          );
          state = AsyncValue.data(next);
        }
        break;
      default:
        break;
    }
  }

  Future<void> _refreshRealtimeMemberships() async {
    final authState = await ref.read(authNotifierProvider.future);
    final isAuthenticated = authState.maybeWhen(
      authenticated: (_) => true,
      orElse: () => false,
    );
    if (!isAuthenticated) return;
    await ref.read(websocketClientProvider).connect();
  }
}

final groupsNotifierProvider =
    AsyncNotifierProvider<GroupsNotifier, List<Group>>(GroupsNotifier.new);

final myPendingJoinRequestsProvider = FutureProvider.autoDispose((ref) {
  ref.watch(sessionResetSignalProvider);
  final repo = ref.read(groupsRepositoryProvider);
  return repo.listMyJoinRequests();
});
