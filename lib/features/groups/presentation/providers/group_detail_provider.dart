import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  final String _groupId;

  @override
  FutureOr<GroupDetailState> build() async {
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
