import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/networking/websocket_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/groups_repository.dart';
import '../../domain/group_model.dart';
import '../../domain/membership_model.dart';

class GroupDetailState {
  const GroupDetailState({
    required this.group,
    this.members = const [],
    this.pendingRequests = const [],
    this.currentUserId,
    this.currentUserRole,
  });

  final Group group;
  final List<GroupMember> members;
  final List<JoinRequest> pendingRequests;
  final String? currentUserId;
  final String? currentUserRole;

  bool get isOwner => currentUserRole == 'owner';
  bool get isAdmin => currentUserRole == 'admin';
  bool get canManageSettings => isOwner || isAdmin;
  bool get canManageRequests => isOwner || isAdmin;
  bool get canManageRoles => isOwner;
  bool get canDeleteGroup => isOwner;

  bool canRemoveMember(GroupMember member) {
    if (!canManageSettings || member.userId == currentUserId) {
      return false;
    }
    return member.role != 'owner';
  }

  bool canPromote(GroupMember member) {
    return canManageRoles &&
        member.userId != currentUserId &&
        member.role == 'member';
  }

  bool canDemote(GroupMember member) {
    return canManageRoles &&
        member.userId != currentUserId &&
        member.role == 'admin';
  }

  bool canTransferOwnershipTo(GroupMember member) {
    return canManageRoles &&
        member.userId != currentUserId &&
        member.role != 'owner';
  }
}

class GroupDetailNotifier extends AsyncNotifier<GroupDetailState> {
  GroupDetailNotifier(this._groupId);

  StreamSubscription<dynamic>? _subscription;
  final String _groupId;

  @override
  FutureOr<GroupDetailState> build() async {
    ref.watch(sessionResetSignalProvider);
    _subscription?.cancel();
    ref.onDispose(() => _subscription?.cancel());
    _subscription =
        ref.read(websocketClientProvider).events.listen(_handleEvent);
    final repo = ref.read(groupsRepositoryProvider);
    final authState = await ref.watch(authNotifierProvider.future);
    final currentUserId = authState.maybeWhen(
      authenticated: (user) => user.id,
      orElse: () => null,
    );
    final group = await repo.getGroup(_groupId);
    final members = await repo.listMembers(_groupId);
    final currentUserRole = _roleForUser(members, currentUserId);

    List<JoinRequest> pendingRequests = [];
    try {
      pendingRequests = await repo.listJoinRequests(_groupId);
    } on DioException catch (error) {
      if (error.response?.statusCode != 403) {
        rethrow;
      }
      // Non-admin users will get 403 — silently ignore
    }

    return GroupDetailState(
      group: group,
      members: members,
      pendingRequests: pendingRequests,
      currentUserId: currentUserId,
      currentUserRole: currentUserRole,
    );
  }

  Future<void> loadMembers() async {
    final currentState = state.value;
    if (currentState == null) return;

    final repo = ref.read(groupsRepositoryProvider);
    final members = await repo.listMembers(_groupId);
    state = AsyncValue.data(
      GroupDetailState(
        group: currentState.group,
        members: members,
        pendingRequests: currentState.pendingRequests,
      ),
    );
  }

  Future<void> resolveRequest(
    String requestId, {
    required bool approved,
  }) async {
    final repo = ref.read(groupsRepositoryProvider);
    await repo.resolveJoinRequest(requestId, approved: approved);
    await refresh();
  }

  Future<void> updateMemberRole(String userId, String role) async {
    final repo = ref.read(groupsRepositoryProvider);
    await repo.updateMemberRole(_groupId, userId, role);
    await refresh();
  }

  Future<void> transferOwnership(String userId) async {
    final repo = ref.read(groupsRepositoryProvider);
    await repo.transferOwnership(_groupId, userId);
    await refresh();
  }

  Future<void> refresh() async {
    final nextState = await AsyncValue.guard(() async => await build());
    state = nextState;
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) return;
    final groupId = event['group_id'] as String?;
    if (groupId != _groupId) return;
    final current = state.value;
    if (current == null) return;

    switch (event['type']) {
      case 'member_joined':
        final userId = event['user_id'] as String?;
        final displayName = event['display_name'] as String?;
        if (userId == null || displayName == null) return;
        if (current.members.any((m) => m.userId == userId)) return;
        state = AsyncValue.data(
          GroupDetailState(
            group: current.group.copyWith(
              memberCount: current.group.memberCount + 1,
            ),
            members: [
              ...current.members,
              GroupMember(
                id: '',
                userId: userId,
                displayName: displayName,
                avatarUrl: event['avatar_url'] as String?,
                role: (event['role'] as String?) ?? 'member',
              ),
            ],
            pendingRequests: current.pendingRequests,
            currentUserId: current.currentUserId,
            currentUserRole: current.currentUserRole,
          ),
        );
        break;
      case 'member_left':
      case 'member_removed':
        final userId = event['user_id'] as String?;
        if (userId == null) return;
        state = AsyncValue.data(
          GroupDetailState(
            group: current.group.copyWith(
              memberCount:
                  (current.group.memberCount - 1).clamp(0, double.maxFinite.toInt()),
            ),
            members:
                current.members.where((m) => m.userId != userId).toList(),
            pendingRequests: current.pendingRequests,
            currentUserId: current.currentUserId,
            currentUserRole: current.currentUserRole,
          ),
        );
        break;
      case 'member_role_changed':
        final userId = event['user_id'] as String?;
        final role = event['role'] as String?;
        if (userId == null || role == null) return;
        final updatedMembers = current.members.map((m) {
          if (m.userId != userId) return m;
          return m.copyWith(role: role);
        }).toList();
        final currentUserRole =
            _roleForUser(updatedMembers, current.currentUserId);
        state = AsyncValue.data(
          GroupDetailState(
            group: current.group,
            members: updatedMembers,
            pendingRequests: current.pendingRequests,
            currentUserId: current.currentUserId,
            currentUserRole: currentUserRole,
          ),
        );
        break;
      case 'group_updated':
        final rawGroup = event['group'];
        if (rawGroup is! Map<String, dynamic>) return;
        try {
          final updatedGroup = Group.fromJson(rawGroup);
          state = AsyncValue.data(
            GroupDetailState(
              group: updatedGroup,
              members: current.members,
              pendingRequests: current.pendingRequests,
              currentUserId: current.currentUserId,
              currentUserRole: current.currentUserRole,
            ),
          );
        } catch (_) {
          // Malformed payload — ignore
        }
        break;
      case 'join_request_created':
        final rawRequest = event['request'];
        if (rawRequest is! Map<String, dynamic>) return;
        if (!current.canManageRequests) return;
        try {
          final request = JoinRequest.fromJson(rawRequest);
          if (current.pendingRequests.any((r) => r.id == request.id)) return;
          state = AsyncValue.data(
            GroupDetailState(
              group: current.group,
              members: current.members,
              pendingRequests: [...current.pendingRequests, request],
              currentUserId: current.currentUserId,
              currentUserRole: current.currentUserRole,
            ),
          );
        } catch (_) {
          // Malformed payload — ignore
        }
        break;
      case 'join_request_resolved':
        final requestId = event['request_id'] as String?;
        if (requestId == null) return;
        state = AsyncValue.data(
          GroupDetailState(
            group: current.group,
            members: current.members,
            pendingRequests: current.pendingRequests
                .where((r) => r.id != requestId)
                .toList(),
            currentUserId: current.currentUserId,
            currentUserRole: current.currentUserRole,
          ),
        );
        break;
      default:
        break;
    }
  }

  String? _roleForUser(List<GroupMember> members, String? userId) {
    if (userId == null) {
      return null;
    }
    for (final member in members) {
      if (member.userId == userId) {
        return member.role;
      }
    }
    return null;
  }
}

final groupDetailNotifierProvider =
    AsyncNotifierProvider.family<GroupDetailNotifier, GroupDetailState, String>(
      GroupDetailNotifier.new,
    );
