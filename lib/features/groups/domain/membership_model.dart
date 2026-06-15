import 'package:freezed_annotation/freezed_annotation.dart';

part 'membership_model.freezed.dart';
part 'membership_model.g.dart';

@freezed
abstract class GroupMember with _$GroupMember {
  const factory GroupMember({
    required String id,
    required String userId,
    required String displayName,
    String? avatarUrl,
    required String role,
    DateTime? joinedAt,
  }) = _GroupMember;

  factory GroupMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberFromJson(json);
}

@freezed
abstract class JoinRequestUser with _$JoinRequestUser {
  const factory JoinRequestUser({
    required String id,
    required String displayName,
    String? avatarUrl,
  }) = _JoinRequestUser;

  factory JoinRequestUser.fromJson(Map<String, dynamic> json) =>
      _$JoinRequestUserFromJson(json);
}

@freezed
abstract class JoinRequest with _$JoinRequest {
  const factory JoinRequest({
    required String id,
    required JoinRequestUser user,
    required String groupId,
    required String status,
    DateTime? createdAt,
    String? resolvedBy,
    DateTime? resolvedAt,
  }) = _JoinRequest;

  factory JoinRequest.fromJson(Map<String, dynamic> json) =>
      _$JoinRequestFromJson(json);
}

@freezed
abstract class MyJoinRequest with _$MyJoinRequest {
  const factory MyJoinRequest({
    required String id,
    required String groupId,
    required String groupName,
    required String status,
    DateTime? createdAt,
  }) = _MyJoinRequest;

  factory MyJoinRequest.fromJson(Map<String, dynamic> json) =>
      _$MyJoinRequestFromJson(json);
}
