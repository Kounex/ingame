import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../domain/group_model.dart';
import '../domain/membership_model.dart';

class GroupsRepository {
  GroupsRepository({required this.dio});

  final Dio dio;

  Future<List<Group>> listMyGroups() async {
    final response = await dio.get(ApiEndpoints.groups);
    final list = response.data as List<dynamic>;
    return list.map((e) => Group.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Group> getGroup(String id) async {
    final response = await dio.get(ApiEndpoints.group(id));
    return Group.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Group> createGroup({
    required String name,
    String? description,
    bool isDiscoverable = false,
    String joinMode = 'open',
  }) async {
    final response = await dio.post(
      ApiEndpoints.groups,
      data: {
        'name': name,
        'description': description,
        'is_discoverable': isDiscoverable,
        'join_mode': joinMode,
      },
    );
    return Group.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Group> updateGroup(String id, Map<String, dynamic> updates) async {
    final response = await dio.patch(ApiEndpoints.group(id), data: updates);
    return Group.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteGroup(String id) async {
    await dio.delete(ApiEndpoints.group(id));
  }

  Future<Group> joinByInviteCode(String code) async {
    final response = await dio.post(ApiEndpoints.joinByCode(code));
    return Group.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Group> previewByInviteCode(String code) async {
    final response = await dio.get(ApiEndpoints.previewJoinByCode(code));
    return Group.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<GroupMember>> listMembers(String groupId) async {
    final response = await dio.get(ApiEndpoints.groupMembers(groupId));
    final list = response.data as List<dynamic>;
    return list
        .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> leaveGroup(String groupId) async {
    await dio.delete(ApiEndpoints.leaveGroup(groupId));
  }

  Future<void> removeMember(String groupId, String userId) async {
    await dio.delete('${ApiEndpoints.groupMembers(groupId)}/$userId');
  }

  Future<void> updateMemberRole(
    String groupId,
    String userId,
    String role,
  ) async {
    await dio.patch(
      ApiEndpoints.groupMemberRole(groupId, userId),
      data: {'role': role},
    );
  }

  Future<void> transferOwnership(String groupId, String userId) async {
    await dio.post(
      ApiEndpoints.transferGroupOwnership(groupId),
      data: {'user_id': userId},
    );
  }

  Future<List<Group>> discoverGroups({String? search}) async {
    final response = await dio.get(
      ApiEndpoints.discoverGroups,
      queryParameters: search != null ? {'search': search} : null,
    );
    final list = response.data as List<dynamic>;
    return list.map((e) => Group.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createJoinRequest(String groupId) async {
    await dio.post(ApiEndpoints.groupJoinRequests(groupId));
  }

  Future<void> createJoinRequestByInviteCode(String code) async {
    await dio.post(ApiEndpoints.joinRequestByCode(code));
  }

  Future<List<JoinRequest>> listJoinRequests(String groupId) async {
    final response = await dio.get(ApiEndpoints.groupJoinRequests(groupId));
    final list = response.data as List<dynamic>;
    return list
        .map((e) => JoinRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> resolveJoinRequest(
    String requestId, {
    required bool approved,
  }) async {
    await dio.patch(
      ApiEndpoints.joinRequest(requestId),
      data: {'status': approved ? 'approved' : 'denied'},
    );
  }
}

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return GroupsRepository(dio: ref.read(dioProvider));
});
