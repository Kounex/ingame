import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/websocket_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/groups_repository.dart';
import '../../domain/group_model.dart';

class GroupsNotifier extends AsyncNotifier<List<Group>> {
  @override
  Future<List<Group>> build() async {
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
  }) async {
    final repo = ref.read(groupsRepositoryProvider);
    final group = await repo.createGroup(
      name: name,
      description: description,
      isDiscoverable: isDiscoverable,
      joinMode: joinMode,
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
