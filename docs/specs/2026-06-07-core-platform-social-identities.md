---
spec: core-platform-social-identities
version: "1.2"
status: active
last_updated: "2026-06-07"
sub_project: 1
---

# InGame -- Core Platform Social Identities Spec

> Part of the [InGame Product Roadmap](roadmap.md) and the [Core Platform overview](2026-05-30-core-platform-design.md)

## Scope

This spec covers the SP1 social-identity contract:

- linked external gaming/social identities
- auth-provider versus social-identity capability boundaries
- provider refresh rules and profile metadata persistence
- manual identity fallbacks for restricted platforms
- profile rendering and outbound social actions

## Design Goal

InGame keeps the app profile (`display_name`, `avatar_url`, `bio`, etc.) separate from external platform identities.

External identities exist so the app can:

- sign a user in when the platform supports official auth
- preserve the platform's current display name, avatar, email, and stable external id when available
- show the user's platform identities on profile and later member-profile surfaces
- open the best available outbound profile/share action so members can find each other off-platform without relying on guessed handles

## Provider Identity Model

Each user may have zero or one identity per provider.

### ProviderIdentity

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Primary key |
| `user_id` | UUID | FK -> User |
| `provider` | VARCHAR | `steam`, `discord`, `apple`, `xbox`, `playstation`, `nintendo` |
| `auth_mode` | VARCHAR | `official_openid`, `official_oauth`, `manual_verified`, `manual_unverified` |
| `external_id` | VARCHAR? | Stable provider id when available; may be null for purely link-based manual identities |
| `username` | VARCHAR? | Provider username / gamertag / online id |
| `display_name` | VARCHAR? | Provider display name or human-facing nickname |
| `email` | VARCHAR? | Provider-sourced email when available |
| `avatar_url` | VARCHAR? | Provider avatar snapshot |
| `profile_url` | VARCHAR? | Official profile link or user-provided share link |
| `metadata` | JSONB? | Provider-specific structured extras such as Nintendo friend code |
| `refresh_token` | VARCHAR? | Stored only when needed for refreshable official providers |
| `access_token_expires_at` | TIMESTAMP? | Optional provider access-token expiry hint |
| `last_synced_at` | TIMESTAMP? | Last successful provider refresh |
| `created_at` | TIMESTAMP | Auto-set |
| `updated_at` | TIMESTAMP | Auto-updated |
| Unique constraint | | (`user_id`, `provider`) |

## Provider Capability Matrix

### Auth Providers

| Provider | Login | Link existing account | Refreshable profile sync | Social identity |
|----------|-------|-----------------------|--------------------------|-----------------|
| `steam` | Yes | Yes | Yes | Yes |
| `discord` | Yes | Yes | Yes | Yes |
| `apple` | Yes | Yes | No social refresh requirement | No |

### Manual Social Providers

| Provider | Login | Manual entry | Best outbound action |
|----------|-------|--------------|----------------------|
| `xbox` | Not in phase 1 | `gamertag` | Generated Xbox profile URL |
| `playstation` | Not in phase 1 | Official shared profile link, optional `online_id` | Open stored share link |
| `nintendo` | Not in phase 1 | `friend_code`, optional `nickname` | Copy/share friend code |

## Canonical Per-Platform Fields

### Steam

- `provider = steam`
- `external_id = steamid`
- `display_name = current Steam persona name`
- `avatar_url = current Steam avatar`
- `profile_url = Steam profile URL returned by Steam`
- refresh path: look up latest Steam profile by `steamid`

### Discord

- `provider = discord`
- `external_id = Discord user id`
- `username = Discord username`
- `display_name = Discord global name when present, otherwise username`
- `email = provider email when granted`
- `avatar_url = Discord CDN avatar URL`
- `profile_url = https://discord.com/users/{external_id}`
- refresh path: use stored Discord refresh token to refresh access, then fetch `/users/@me`

### Apple

- `provider = apple`
- `external_id = Apple subject`
- `email = provider email when present`
- no social outbound profile action
- the identity exists for auth lifecycle and account-management visibility only

### Xbox

- `provider = xbox`
- canonical manual field: `username = gamertag`
- optional future official field: `external_id = xuid`
- `profile_url` is derived from the gamertag

### PlayStation

- `provider = playstation`
- canonical manual field: `profile_url = official shared profile link`
- optional display field: `username = online_id`
- do not treat PlayStation as “name only”; the share link is the stronger social artifact

### Nintendo

- `provider = nintendo`
- canonical manual field: `metadata.friend_code`
- optional display field: `display_name = nickname`
- do not model Nintendo around a public web profile URL; the friend code is the connect primitive

## Auth And Linking Contract

### Official Flows

- Steam auth/link continues validating OpenID, then refreshes the linked Steam identity record from the Steam profile API.
- Discord auth/link uses OAuth authorization code with PKCE and stores the resulting provider identity plus refresh token for later sync.
- Apple auth/link continues validating the Apple identity token and stores an auth-only identity record.

### Lockout Guard

The “last auth method” rule counts only auth-capable methods:

- email/password
- linked Steam identity
- linked Discord identity
- linked Apple identity

Manual Xbox / PlayStation / Nintendo entries must not affect auth lockout checks.

### Revoked Provider Lifecycle

Revoked-provider records remain keyed by `{provider, external_id}` and continue to block direct login with unlinked official identities until the user signs in another way and explicitly relinks that provider.

## Refresh Rules

Official identity data should stay current without overwriting the user's app profile.

### Refresh triggers

- successful login with that provider
- successful relink of that provider
- profile-page load when `last_synced_at` is stale

### Refresh outcomes

- update provider identity fields only
- do not silently overwrite the app's main `display_name` or `avatar_url`
- keep manual identities untouched except when the user edits them

## Profile Rendering Contract

The profile screen should distinguish:

- app profile
- auth providers
- social identities

Each rendered provider row should show:

- provider label
- connected / manual / auth-only status
- current provider display label where available
- outbound action based on provider capability

Examples:

- Steam -> open profile
- Discord -> open profile
- Xbox -> open generated profile URL
- PlayStation -> open stored share link
- Nintendo -> copy friend code
- Apple -> no social action

## API Response Shape

`UserResponse` should expose linked provider identities through a structured collection instead of requiring new top-level provider-specific fields for every platform.

Transition compatibility may keep derived helper fields such as `steam_id` or `apple_id` temporarily while Flutter migrates, but the durable source of truth becomes the provider-identity collection.

## Change Log

| Date | Section | What changed | Why |
|------|---------|--------------|-----|
| 2026-06-07 | Outbound actions | Narrowed Nintendo’s maintained outbound action wording from copy/share to copy-only | Keeps the written social-identity contract aligned with the shipped/profile-tested Nintendo interaction instead of overstating an unimplemented share affordance |
| 2026-06-07 | Refresh triggers | Removed the unshipped manual refresh trigger from the maintained refresh contract | Keeps the written social-identity spec aligned with the current Flutter/backend surfaces instead of implying a user-facing refresh action already exists |
| 2026-06-07 | Initial spec | Added the SP1 social-identity contract covering provider capabilities, normalized identity storage, refresh rules, and manual-provider fallbacks | Creates a stable contract before expanding beyond Steam and Apple so auth and social-connect features scale without hardcoding new provider columns into the user model |
