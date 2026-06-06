import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/features/groups/data/groups_repository.dart';
import 'package:ingame/features/groups/domain/group_model.dart';
import 'package:ingame/features/groups/domain/membership_model.dart';
import 'package:ingame/features/groups/presentation/providers/group_detail_provider.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => const AuthState.authenticated(
    User(id: 'owner-1', displayName: 'Owner', timezone: 'UTC'),
  );
}

class _MutableGroupsRepository extends GroupsRepository {
  _MutableGroupsRepository()
    : _group = const Group(
        id: 'group-1',
        name: 'Raid Night',
        inviteCode: 'ABC123',
        isDiscoverable: false,
        joinMode: 'open',
        createdBy: 'owner-1',
        memberCount: 3,
      ),
      _members = [
        const GroupMember(
          id: 'm-owner',
          userId: 'owner-1',
          displayName: 'Owner',
          role: 'owner',
        ),
        const GroupMember(
          id: 'm-admin',
          userId: 'admin-1',
          displayName: 'Admin',
          role: 'admin',
        ),
        const GroupMember(
          id: 'm-member',
          userId: 'member-1',
          displayName: 'Member',
          role: 'member',
        ),
      ],
      super(dio: Dio());

  final Group _group;
  final List<GroupMember> _members;

  @override
  Future<Group> getGroup(String id) async => _group;

  @override
  Future<List<GroupMember>> listMembers(String groupId) async =>
      List.of(_members);

  @override
  Future<List<JoinRequest>> listJoinRequests(String groupId) async => const [];

  @override
  Future<void> updateMemberRole(
    String groupId,
    String userId,
    String role,
  ) async {
    final index = _members.indexWhere((member) => member.userId == userId);
    _members[index] = _members[index].copyWith(role: role);
  }
}

class _FailingJoinRequestsRepository extends _MutableGroupsRepository {
  @override
  Future<List<JoinRequest>> listJoinRequests(String groupId) async {
    final request = RequestOptions(path: '/groups/$groupId/join-requests');
    throw DioException(
      requestOptions: request,
      response: Response(
        requestOptions: request,
        statusCode: 500,
        data: const {'detail': 'Server error'},
      ),
      type: DioExceptionType.badResponse,
    );
  }
}

GroupDetailState _state({
  required String currentUserId,
  required String currentUserRole,
  required List<GroupMember> members,
}) {
  return GroupDetailState(
    group: const Group(
      id: 'group-1',
      name: 'Raid Night',
      inviteCode: 'ABC123',
      isDiscoverable: false,
      joinMode: 'open',
      createdBy: 'owner-1',
      memberCount: 3,
    ),
    members: members,
    currentUserId: currentUserId,
    currentUserRole: currentUserRole,
  );
}

void main() {
  test('owner can promote, demote, transfer ownership, and remove others', () {
    final ownerState = _state(
      currentUserId: 'owner-1',
      currentUserRole: 'owner',
      members: const [
        GroupMember(
          id: 'm-owner',
          userId: 'owner-1',
          displayName: 'Owner',
          role: 'owner',
        ),
        GroupMember(
          id: 'm-admin',
          userId: 'admin-1',
          displayName: 'Admin',
          role: 'admin',
        ),
        GroupMember(
          id: 'm-member',
          userId: 'member-1',
          displayName: 'Member',
          role: 'member',
        ),
      ],
    );

    expect(ownerState.canManageSettings, isTrue);
    expect(ownerState.canDeleteGroup, isTrue);
    expect(ownerState.canPromote(ownerState.members[2]), isTrue);
    expect(ownerState.canDemote(ownerState.members[1]), isTrue);
    expect(ownerState.canTransferOwnershipTo(ownerState.members[1]), isTrue);
    expect(ownerState.canRemoveMember(ownerState.members[1]), isTrue);
    expect(ownerState.canRemoveMember(ownerState.members[0]), isFalse);
  });

  test('admin can manage settings but cannot manage roles or delete', () {
    final adminState = _state(
      currentUserId: 'admin-1',
      currentUserRole: 'admin',
      members: const [
        GroupMember(
          id: 'm-owner',
          userId: 'owner-1',
          displayName: 'Owner',
          role: 'owner',
        ),
        GroupMember(
          id: 'm-admin',
          userId: 'admin-1',
          displayName: 'Admin',
          role: 'admin',
        ),
        GroupMember(
          id: 'm-member',
          userId: 'member-1',
          displayName: 'Member',
          role: 'member',
        ),
      ],
    );

    expect(adminState.canManageSettings, isTrue);
    expect(adminState.canDeleteGroup, isFalse);
    expect(adminState.canPromote(adminState.members[2]), isFalse);
    expect(adminState.canDemote(adminState.members[1]), isFalse);
    expect(adminState.canTransferOwnershipTo(adminState.members[2]), isFalse);
    expect(adminState.canRemoveMember(adminState.members[2]), isTrue);
  });

  test(
    'updateMemberRole refreshes in place without emitting loading',
    () async {
      final repository = _MutableGroupsRepository();
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          groupsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final states = <AsyncValue<GroupDetailState>>[];
      final sub = container.listen(
        groupDetailNotifierProvider('group-1'),
        (previous, next) => states.add(next),
        fireImmediately: true,
      );
      addTearDown(sub.close);

      await container.read(groupDetailNotifierProvider('group-1').future);
      states.clear();

      await container
          .read(groupDetailNotifierProvider('group-1').notifier)
          .updateMemberRole('member-1', 'admin');

      expect(states.where((state) => state.isLoading), isEmpty);
      expect(
        container
            .read(groupDetailNotifierProvider('group-1'))
            .value!
            .members
            .singleWhere((member) => member.userId == 'member-1')
            .role,
        'admin',
      );
    },
  );

  test('admin join-request loading surfaces non-permission failures', () async {
    final repository = _FailingJoinRequestsRepository();
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
        groupsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    container.read(groupDetailNotifierProvider('group-1'));
    await Future<void>.delayed(Duration.zero);

    final state = container.read(groupDetailNotifierProvider('group-1'));
    expect(state.hasError, isTrue);
    expect(state.error, isA<DioException>());
  });
}
