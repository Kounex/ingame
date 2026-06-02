import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String displayName,
    String? email,
    @Default(false) bool hasPasswordLogin,
    String? avatarUrl,
    String? bio,
    required String timezone,
    Map<String, dynamic>? preferredGamingHours,
    String? steamId,
    String? appleId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
