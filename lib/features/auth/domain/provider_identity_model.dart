import 'package:json_annotation/json_annotation.dart';

part 'provider_identity_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProviderIdentity {
  const ProviderIdentity({
    required this.provider,
    required this.authMode,
    this.externalId,
    this.username,
    this.displayName,
    this.email,
    this.avatarUrl,
    this.profileUrl,
    this.metadata,
    this.lastSyncedAt,
    required this.supportsLogin,
    required this.supportsRefresh,
    required this.supportsDirectProfileLink,
    required this.supportsManualEntry,
    required this.supportsCopyOnlyAction,
    required this.isSocialIdentity,
  });

  factory ProviderIdentity.fromJson(Map<String, dynamic> json) =>
      _$ProviderIdentityFromJson(json);

  final String provider;
  final String authMode;
  final String? externalId;
  final String? username;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final String? profileUrl;
  final Map<String, dynamic>? metadata;
  final DateTime? lastSyncedAt;
  final bool supportsLogin;
  final bool supportsRefresh;
  final bool supportsDirectProfileLink;
  final bool supportsManualEntry;
  final bool supportsCopyOnlyAction;
  final bool isSocialIdentity;

  Map<String, dynamic> toJson() => _$ProviderIdentityToJson(this);
}
