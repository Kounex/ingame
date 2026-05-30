import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  }
}

final groupsNotifierProvider =
    AsyncNotifierProvider<GroupsNotifier, List<Group>>(GroupsNotifier.new);
