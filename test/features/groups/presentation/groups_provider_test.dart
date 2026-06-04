import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/networking/websocket_client.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/features/groups/data/groups_repository.dart';
import 'package:ingame/features/groups/domain/group_model.dart';
import 'package:ingame/features/groups/presentation/providers/groups_provider.dart';

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);

  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

class _FakeWebSocketClient extends WebSocketClient {
  _FakeWebSocketClient()
    : super(
        baseUrl: 'ws://example.test/api/v1/ws',
        getAccessToken: () async => 'token',
      );

  int connectCalls = 0;

  @override
  Future<void> connect() async {
    connectCalls++;
  }
}

class _FakeGroupsRepository extends GroupsRepository {
  _FakeGroupsRepository({required List<Group> initialGroups})
    : _groups = List<Group>.from(initialGroups),
      super(dio: Dio());

  List<Group> _groups;

  Group get createdGroup => _groups.last;

  @override
  Future<List<Group>> listMyGroups() async => List<Group>.from(_groups);

  @override
  Future<Group> createGroup({
    required String name,
    String? description,
    bool isDiscoverable = false,
    String joinMode = 'open',
  }) async {
    final group = Group(
      id: 'group-created',
      name: name,
      description: description,
      inviteCode: 'CREATE1',
      isDiscoverable: isDiscoverable,
      joinMode: joinMode,
      createdBy: 'user-1',
      memberCount: 1,
    );
    _groups = [..._groups, group];
    return group;
  }

  @override
  Future<Group> joinByInviteCode(String code) async {
    final group = Group(
      id: 'group-joined',
      name: 'Joined Group',
      inviteCode: code,
      isDiscoverable: true,
      joinMode: 'open',
      createdBy: 'owner-1',
      memberCount: 2,
    );
    _groups = [..._groups, group];
    return group;
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    _groups = _groups.where((group) => group.id != groupId).toList();
  }
}

Group _group({
  required String id,
  required String name,
}) => Group(
  id: id,
  name: name,
  inviteCode: 'INVITE1',
  isDiscoverable: false,
  joinMode: 'open',
  createdBy: 'user-1',
  memberCount: 1,
);

ProviderContainer _createContainer({
  required _FakeGroupsRepository repository,
  required _FakeWebSocketClient websocketClient,
}) {
  return ProviderContainer(
    overrides: [
      groupsRepositoryProvider.overrideWithValue(repository),
      websocketClientProvider.overrideWithValue(websocketClient),
      authNotifierProvider.overrideWith(
        () => _FixedAuthNotifier(
          const AuthState.authenticated(
            User(id: 'user-1', displayName: 'Ready Player', timezone: 'UTC'),
          ),
        ),
      ),
    ],
  );
}

void main() {
  test('create refreshes websocket memberships after adding a new group', () async {
    final repository = _FakeGroupsRepository(
      initialGroups: [_group(id: 'group-1', name: 'Existing Group')],
    );
    final websocketClient = _FakeWebSocketClient();
    final container = _createContainer(
      repository: repository,
      websocketClient: websocketClient,
    );
    addTearDown(container.dispose);

    await container.read(groupsNotifierProvider.future);

    final createdGroup = await container
        .read(groupsNotifierProvider.notifier)
        .create(name: 'New Group');

    expect(createdGroup.id, 'group-created');
    expect(websocketClient.connectCalls, 1);
  });

  test('joinByInviteCode refreshes websocket memberships after joining a group', () async {
    final repository = _FakeGroupsRepository(
      initialGroups: [_group(id: 'group-1', name: 'Existing Group')],
    );
    final websocketClient = _FakeWebSocketClient();
    final container = _createContainer(
      repository: repository,
      websocketClient: websocketClient,
    );
    addTearDown(container.dispose);

    await container.read(groupsNotifierProvider.future);

    final joinedGroup = await container
        .read(groupsNotifierProvider.notifier)
        .joinByInviteCode('JOIN123');

    expect(joinedGroup.id, 'group-joined');
    expect(websocketClient.connectCalls, 1);
  });

  test('leaveGroup refreshes websocket memberships after leaving a group', () async {
    final repository = _FakeGroupsRepository(
      initialGroups: [
        _group(id: 'group-1', name: 'Existing Group'),
        _group(id: 'group-2', name: 'Leaving Group'),
      ],
    );
    final websocketClient = _FakeWebSocketClient();
    final container = _createContainer(
      repository: repository,
      websocketClient: websocketClient,
    );
    addTearDown(container.dispose);

    await container.read(groupsNotifierProvider.future);

    await container.read(groupsNotifierProvider.notifier).leaveGroup('group-2');

    expect(websocketClient.connectCalls, 1);
  });
}
