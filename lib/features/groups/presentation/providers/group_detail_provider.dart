import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/groups_repository.dart';
import '../../domain/group_model.dart';
import '../../domain/membership_model.dart';

class GroupDetailState {
  const GroupDetailState({
    required this.group,
    this.members = const [],
    this.pendingRequests = const [],
  });

  final Group group;
  final List<GroupMember> members;
  final List<JoinRequest> pendingRequests;
}

class GroupDetailNotifier
    extends FamilyAsyncNotifier<GroupDetailState, String> {
  @override
  Future<GroupDetailState> build(String arg) async {
    final repo = ref.read(groupsRepositoryProvider);
    final group = await repo.getGroup(arg);
    final members = await repo.listMembers(arg);

    List<JoinRequest> pendingRequests = [];
    try {
      pendingRequests = await repo.listJoinRequests(arg);
    } on Exception {
      // Non-admin users will get 403 — silently ignore
    }

    return GroupDetailState(
      group: group,
      members: members,
      pendingRequests: pendingRequests,
    );
  }

  Future<void> loadMembers() async {
    final currentState = state.value;
    if (currentState == null) return;

    final repo = ref.read(groupsRepositoryProvider);
    final members = await repo.listMembers(arg);
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

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(arg));
  }
}

final groupDetailNotifierProvider = AsyncNotifierProvider.family<
    GroupDetailNotifier, GroupDetailState, String>(GroupDetailNotifier.new);
