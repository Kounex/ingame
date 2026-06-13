import 'package:flutter/material.dart';

import '../../core/utils/extensions.dart';
import '../../features/auth/domain/provider_identity_model.dart';
import '../../features/auth/domain/user_model.dart';
import '../widgets/social_identities_card.dart';

ProviderIdentity? socialIdentityFor(
  String provider, {
  required String? steamId,
  required List<ProviderIdentity> providerIdentities,
}) {
  for (final identity in providerIdentities) {
    if (identity.provider == provider) {
      return identity;
    }
  }
  if (provider == 'steam' && steamId != null) {
    return ProviderIdentity(
      provider: 'steam',
      authMode: 'official_openid',
      externalId: steamId,
      profileUrl: 'https://steamcommunity.com/profiles/$steamId',
      supportsLogin: true,
      supportsRefresh: true,
      supportsDirectProfileLink: true,
      supportsManualEntry: false,
      supportsCopyOnlyAction: false,
      isSocialIdentity: true,
    );
  }
  return null;
}

String socialProviderLabel(BuildContext context, String provider) {
  return switch (provider) {
    'steam' => context.l10n.profileConnectedAccountsSteam,
    'discord' => context.l10n.profileConnectedAccountsDiscord,
    'xbox' => context.l10n.profileConnectedAccountsXbox,
    'playstation' => context.l10n.profileConnectedAccountsPlayStation,
    'nintendo' => context.l10n.profileConnectedAccountsNintendo,
    _ => provider,
  };
}

String socialIdentityStatus(
  BuildContext context, {
  required String provider,
  required ProviderIdentity? identity,
}) {
  if (identity == null) {
    if (provider == 'steam' || provider == 'discord') {
      return context.l10n.profileNotConnected;
    }
    return context.l10n.profileNotSet;
  }

  final friendCode = nintendoFriendCode(identity);
  final parts = switch (provider) {
    'discord' => _distinctNonEmpty([
      identity.displayName,
      _discordHandle(identity.username),
    ]),
    'nintendo' => _distinctNonEmpty([identity.displayName, friendCode]),
    'playstation' => () {
      final preferred = _distinctNonEmpty([
        identity.username,
        identity.displayName,
      ]);
      return preferred.isNotEmpty
          ? preferred
          : _distinctNonEmpty([socialProfileUrl(identity)]);
    }(),
    'steam' => () {
      final preferred = _distinctNonEmpty([
        identity.displayName,
        identity.username,
      ]);
      return preferred.isNotEmpty
          ? preferred
          : _distinctNonEmpty([identity.externalId]);
    }(),
    _ => _distinctNonEmpty([
      identity.displayName,
      identity.username,
      friendCode,
      identity.externalId,
    ]),
  };
  return parts.isEmpty ? context.l10n.profileConnected : parts.join(' • ');
}

List<SocialIdentityCardEntry> buildReadOnlySocialEntries(
  BuildContext context,
  User user,
) {
  const providers = ['steam', 'discord', 'xbox', 'playstation', 'nintendo'];
  final entries = <SocialIdentityCardEntry>[];

  for (final provider in providers) {
    final identity = socialIdentityFor(
      provider,
      steamId: user.steamId,
      providerIdentities: user.providerIdentities,
    );
    if (identity == null) continue;

    entries.add(SocialIdentityCardEntry(
      provider: provider,
      label: socialProviderLabel(context, provider),
      connected: true,
      subtitle: socialIdentityStatus(
        context,
        provider: provider,
        identity: identity,
      ),
    ));
  }

  return entries;
}

List<String> _distinctNonEmpty(List<String?> values) {
  final seen = <String>{};
  final items = <String>[];
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) continue;
    final key = trimmed.toLowerCase();
    if (!seen.add(key)) continue;
    items.add(trimmed);
  }
  return items;
}

String? _discordHandle(String? username) {
  final trimmed = username?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.startsWith('@') ? trimmed : '@$trimmed';
}

String? socialProfileUrl(ProviderIdentity? identity) {
  final profileUrl = identity?.profileUrl?.trim();
  if (profileUrl == null || profileUrl.isEmpty) return null;
  return profileUrl;
}

String? nintendoFriendCode(ProviderIdentity? identity) {
  final friendCode =
      (identity?.metadata?['friend_code'] as String?)?.trim() ??
      identity?.externalId?.trim();
  if (friendCode == null || friendCode.isEmpty) return null;
  return friendCode;
}
