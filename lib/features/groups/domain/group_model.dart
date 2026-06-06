import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_model.freezed.dart';
part 'group_model.g.dart';

@freezed
abstract class Group with _$Group {
  const factory Group({
    required String id,
    required String name,
    String? description,
    required String inviteCode,
    required bool isDiscoverable,
    required String joinMode,
    String? avatarUrl,
    required String createdBy,
    required int memberCount,
    @Default(false) bool hasPendingJoinRequest,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Group;

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
}
