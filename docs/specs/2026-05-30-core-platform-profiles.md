---
spec: core-platform-profiles
version: "1.22"
status: complete
last_updated: "2026-06-13"
sub_project: 1
---

# InGame -- Core Platform Profiles Spec

> Part of the [InGame Product Roadmap](roadmap.md) and the [Core Platform overview](2026-05-30-core-platform-design.md)

## Scope

This spec covers the SP1 user-profile contract:
- user profile fields and persistence
- avatar behavior and upload rules
- onboarding profile setup
- profile editing
- recurring availability editing and display
- profile rendering for linked social identities

## User Profile Data Model

### User Table

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | Primary key |
| `email` | VARCHAR | Unique, nullable for pre-onboarding Steam-only users |
| `display_name` | VARCHAR | Required |
| `avatar_url` | VARCHAR | Nullable; canonical stored avatar URL |
| `bio` | TEXT | Nullable |
| `timezone` | VARCHAR | Example: `Europe/Berlin` |
| `preferred_gaming_hours` | JSONB | Weekly recurring availability |
| `created_at` | TIMESTAMP | Auto-set |
| `updated_at` | TIMESTAMP | Auto-updated |

### Profile Field Notes

- `preferred_gaming_hours` is the recurring profile-availability field for SP1.
- It may be empty.
- It is edited through the shared per-day preset editor in both onboarding and profile editing.
- Each day can store multiple preset ranges.
- The UI may collapse the four-preset full-day combination into an `All day` shortcut.
- This field remains distinct from future game-preference models in later sub-projects.
- Linked external platform identities are modeled separately from the profile row itself; see [Core Platform Social Identities](2026-06-07-core-platform-social-identities.md).

## Avatar Contract

### Persistence Rule

- `avatar_url` remains the only persisted avatar field on the user.
- PostgreSQL stores only the final URL reference.
- Avatar bytes are **not** stored in the database or embedded as base64 in profile JSON.
- Official provider login/link flows may seed `avatar_url` once from fetched provider metadata when the canonical profile avatar is still empty, but later provider syncs must not overwrite an avatar the user already has.
- `POST /api/v1/users/me/avatar-upload/init` records each issued app-managed upload in a pending server-side ledger, but does not change the canonical persisted `avatar_url` on its own.
- When a user replaces or clears a storage-backed profile avatar, the backend deletes the previously active app-managed object after the profile change commits.
- The same post-commit cleanup also sweeps the user's app-managed avatar prefix so stale sibling uploads and abandoned upload-init objects are removed, while preserving the currently active managed object if one remains.
- A background janitor deletes tracked app-managed uploads that were never committed through `PATCH /api/v1/users/me` once they have remained unclaimed for 24 hours, then removes their ledger rows for retry-safe cleanup.
- If onboarding or another flow is abandoned after upload-init, the previously persisted canonical avatar remains the fallback returned by `GET /api/v1/users/me` until a later successful profile update actually stores a new `avatar_url`.
- External/provider-hosted avatar URLs are never deleted by this cleanup path.

### Allowed Sources

The shared avatar editor supports:

- `Photo library` on iOS/Android
- `Upload photo` through the system file picker on iOS/Android/Web
- `Take photo` on iOS/Android
- `Use image URL`
- `Remove photo`

If a provider avatar already exists (for example from Steam), the editor shows it as the current avatar, allows direct re-cropping when the avatar is tapped, and offers a separate `Change photo` action for switching sources without provider-specific special casing.

### Upload Flow

All image sources except `Remove photo` follow this flow:

1. Flutter acquires the source image.
2. Flutter normalizes the source to editor-ready image bytes, including:
   - newly picked local files
   - newly captured camera images
   - fetched remote image URLs
   - the currently displayed avatar when the user taps it to edit
3. Flutter opens the shared square avatar editor before upload.
4. Flutter requests a presigned upload contract from the backend.
5. Flutter uploads the prepared image directly to S3-compatible object storage.
6. Flutter persists the returned `avatar_url` through `PATCH /api/v1/users/me`.

The upload-init step only creates a pending upload plus direct-upload contract. The backend treats that object as disposable until a later successful profile update commits the returned `avatar_url`.

### Storage Topology

- Local development composes in a self-hosted MinIO service, bootstraps the
  avatar bucket automatically, and enables MinIO browser-upload CORS so
  upload-init works out of the box.
- Release-style deployments may either point at any external S3-compatible
  storage service or use the bundled MinIO service that now ships by default in
  the release compose stack for self-hosted environments.
- Environments may provide a browser-facing upload base URL distinct from the
  API's internal object-storage endpoint so presigned uploads still work when
  storage is private on the app network but public on a separate host.
- The API and Flutter contract stays unchanged across these topologies; only the
  storage endpoint, credentials, and public base URL vary by environment.

### Validation Rules

- Allowed upload MIME types: `image/jpeg`, `image/png`, `image/webp`
- Max upload size: small-avatar scale (currently configured through backend settings)
- Web first implementation supports `Upload photo` and `Use image URL`, but intentionally skips browser-camera capture
- `Use image URL` no longer stores external URLs directly; Flutter fetches the remote image, routes it through the editor, uploads the cropped result, and persists the returned storage-backed `avatar_url`
- Web direct uploads depend on object-storage/browser CORS allowing the presigned POST target

### Clearing Rule

`PATCH /api/v1/users/me` distinguishes omitted fields from explicit nulls. Sending `avatar_url: null` clears the current avatar instead of being ignored.

If the cleared avatar previously pointed at app-managed object storage, the backend removes that old object after the successful profile update commit and sweeps any remaining objects under the same user avatar prefix so no superseded managed avatar upload remains retained.

## Profile Endpoints

- `GET /api/v1/users/me` -- returns the current user profile
- `PATCH /api/v1/users/me` -- updates profile fields including `email`, `display_name`, `avatar_url`, `bio`, `timezone`, `preferred_gaming_hours`
- `POST /api/v1/users/me/avatar-upload/init` -- validates avatar file metadata and returns a presigned upload contract plus final `avatar_url`

### Avatar Upload Init Contract

Request:
- `filename`
- `content_type`
- `byte_size`

Response:
- `upload_url`
- `upload_fields`
- `object_key`
- `avatar_url`
- `expires_in_seconds`
- `max_file_size_bytes`
- `allowed_content_types`

### Avatar Upload Failure Contract

Stable business-rule failures for `POST /api/v1/users/me/avatar-upload/init` include:

- `user.avatar_content_type_invalid` -- unsupported MIME type; returned with `422`
- `user.avatar_file_too_large` -- file exceeds the configured max size; returned with `422`
- `user.avatar_upload_unavailable` -- upload storage is missing, misconfigured, or temporarily unavailable; returned with `503`

Flutter treats these codes as contract-sensitive and resolves user-facing copy from localized client messaging rather than depending on backend English detail strings.

## Shared Flutter Profile Components

### Shared Avatar Editor

`EditableAvatarField` is the reusable avatar editor used by both onboarding and profile editing. It is responsible for:

- rendering the current avatar preview with a camera badge affordance
- opening the source chooser when tapped without an existing avatar
- opening the shared square editor directly when tapped with an existing avatar
- normalizing every supported source into the shared editor flow before upload
- local URL-entry validation
- upload progress display
- direct-to-storage upload orchestration through `AvatarUploadService`

The shared square editor (`AvatarEditorDialog`) provides an in-editor toolbar
with source-switching and avatar removal, so the field itself renders only the
avatar and upload progress — no standalone buttons or hint text.

It is **not** responsible for form submission timing or overall profile persistence ownership; screens still decide when to call `updateProfile(...)`.

### Shared Avatar Display

`UserAvatar` remains the low-level display primitive used throughout the app. It supports:

- `avatar_url`
- in-memory image preview bytes for freshly selected avatars
- initials fallback when no avatar is available

### Shared Availability Editor

`WeeklyAvailabilityEditor` remains the shared recurring-availability editor used by:

- onboarding
- profile editing

### Shared Social Identities Card

`SocialIdentitiesCard` is the reusable provider-row card used by profile surfaces that render social identities. It owns the shared glass card layout, provider icon treatment, row affordances, and subtitle rendering space so the current profile screen and future member-social sheets can present the same social rows with different actions.

## User Flows

### Onboarding

Flow:

`Welcome` -> `Profile Setup` -> `Gaming Preferences`

Profile setup requirements:

- display name is required
- recovery email is required before onboarding completion
- bio remains editable and can default to the shared onboarding fallback
- timezone uses the same shared selector contract as profile editing and must be persisted on onboarding completion
- avatar is optional

The onboarding profile step uses the same avatar editor contract as profile editing.

### Profile Settings Hub

For post-onboarding users, the profile screen itself is the maintained settings
hub. Routine personal-profile edits should not require navigating to a dedicated
full-screen `Edit Profile` route.

The profile hub allows updates to:

- display name
- canonical account email
- bio
- timezone
- avatar
- recurring availability
- local app preferences surfaced there, such as language

The maintained interaction model is mixed:

- obvious single-setting edits should open directly from a tap on the avatar,
  row, or card
- settings that benefit from a focused editor may use a dedicated dialog,
  bottom sheet, or anchored selector rather than a separate screen
- cards with multiple equally valid actions may expose a subtle overflow menu
  for secondary actions while preserving tap for the primary action
- destructive or infrequent actions should remain secondary and must not replace
  the row's most likely tap outcome

Profile-data changes still save through `PATCH /api/v1/users/me`; local app
preferences continue using their own maintained persistence path.

## Profile Rendering Contract

The profile screen:

- shows the avatar at the top
- treats the avatar hero as directly editable on tap; the crop editor itself
  provides source-switching and removal through an in-editor toolbar
- acts as the primary post-onboarding settings surface instead of routing common
  profile edits through a separate dedicated edit screen
- keeps high-frequency personal fields such as display name, bio, timezone, and
  recurring availability on direct-tap entry points that open focused editors in
  place
- shows email and timezone in the account section
- treats the account email row as the dedicated entry point for changing the canonical recovery/sign-in email after onboarding
- treats preferences-style rows such as language as direct selectors rather than
  as navigation into another settings subpage
- shows recurring gaming hours using an intelligent grouped display
- uses `has_password_login` for connected-account state
- splits provider identity rendering into `Connected Accounts` for auth/login providers and `Socials` for social-facing identities
- keeps `Connected Accounts` subtitles status-oriented: connected auth rows show `Connected`, disconnected auth rows show `Not connected`, and only rows with an available connect/disconnect action show a chevron affordance
- keeps `Connected Accounts` action handling primary-action-first: row tap
  performs the most likely connect/disconnect flow, while secondary management
  actions may live in a subtle overflow affordance when needed
- always renders Steam in `Socials`, and renders Discord there whenever the platform can start Discord sign-in or an identity is already linked
- treats disconnected Steam/Discord rows in `Socials` as login-entry points: they show `Not connected` and tap into the same sign-in/link flow used by `Connected Accounts`
- treats connected Steam/Discord rows in `Socials` as social-profile rows: they show provider identity details instead of `Connected`, open the provider profile externally when a direct profile URL is available, and otherwise remain non-interactive
- treats disconnected Xbox / PlayStation / Nintendo rows in `Socials` as manual-entry prompts with a `Not set` subtitle
- treats connected manual socials as social-action-first rows: Xbox opens the generated profile URL, PlayStation opens the stored share link, and Nintendo copies the friend code while a secondary overflow/menu affordance remains available for edit or removal
- formats connected social subtitles from the stored provider identity details rather than generic status text; when helpful, multiple values may be concatenated into one subtitle (for example Nintendo nickname plus friend code)
- uses the shared provider-visual registry for standalone provider rows, with branded `line_icons` glyphs where available, explicit shared fallbacks otherwise, and provider-tinted or platform-appropriate monochrome icon treatment while keeping the existing glass-row layout
- keeps the app profile (`display_name`, `avatar_url`) visually separate from provider-owned identity snapshots

## Localization And UX Rules

- All user-facing copy for avatar flows lives in `lib/l10n/app_en.arb` and `lib/l10n/app_de.arb`
- Widgets use `context.l10n`
- Toasts, helper text, and dialog copy must not introduce inline English strings

## Change Log

| Date | Section | What changed | Why |
|------|---------|--------------|-----|
| 2026-06-13 | Shared avatar editor and profile rendering | Moved source-switching and avatar removal into the crop editor toolbar; removed the standalone `Change photo` button and hint text from `EditableAvatarField` so the camera badge is the sole avatar-editing affordance | Simplifies the profile header layout by placing name and bio directly beneath the avatar with no interstitial UI |
| 2026-06-10 | Avatar contract and upload flow | Added the pending upload ledger, 24-hour unclaimed-upload janitor rule, and the clarification that upload-init alone never replaces the persisted canonical/provider avatar | Keeps the profile/avatar contract aligned with the new TTL cleanup path while preserving the expected fallback avatar when onboarding is abandoned before profile save |
| 2026-06-10 | Avatar contract and clearing rule | Documented that committed avatar save/clear now sweeps stale sibling uploads and abandoned upload-init objects in the same user avatar prefix while still preserving the active managed object and ignoring external/provider URLs | Keeps the profile/avatar storage contract aligned with the new opportunistic orphan cleanup behavior without changing the client upload contract |
| 2026-06-10 | Avatar contract and clearing rule | Documented that replacing or clearing an app-managed canonical avatar deletes the previous stored object after the profile update commits, while external/provider URLs are left untouched | Keeps the profile/avatar storage contract aligned with the new backend cleanup behavior and avoids unbounded growth of superseded avatar objects |
| 2026-06-08 | Profile settings hub and profile rendering | Replaced the dedicated post-onboarding edit-profile-screen expectation with a mixed in-page settings hub contract: direct taps for obvious fields, focused sheets/dialogs/selectors where needed, and overflow menus only for secondary multi-action cases | Keeps the written profile UX aligned with the approved shift toward faster, more polished in-place editing instead of routing most changes through a redundant full-screen form |
| 2026-06-08 | Shared components and profile rendering | Added the reusable `SocialIdentitiesCard` contract and clarified the maintained subtitle/tap rules for connected accounts plus login-based versus manual social rows | Keeps the written profile UI contract aligned with the shared social-card refactor and the approved connected/not-connected/not-set subtitle behavior |
| 2026-06-07 | Avatar contract | Documented that official provider login/link flows may seed the canonical profile avatar once when it is empty, while later provider syncs must not overwrite an existing avatar | Keeps the written profile/avatar contract aligned with the new Discord avatar bootstrap behavior without weakening user control over custom profile photos |
| 2026-06-07 | Edit profile and profile rendering | Added the dedicated profile-level canonical email change flow and clarified that the account email row is the maintained entry point for updating it after onboarding | Keeps post-onboarding email management consistent instead of hiding email edits in the separate add-password flow |
| 2026-06-07 | Provider visuals | Clarified that standalone provider rows may use platform-appropriate monochrome treatment in addition to provider-tinted icons, covering Apple on the dark profile surface | Keeps the written profile contract aligned with the shipped Apple row visuals after the audit follow-through corrected contrast |
| 2026-06-07 | Provider visuals | Clarified that provider rows use branded `line_icons` glyphs where available and shared fallback glyphs otherwise | Keeps the written profile contract aligned with the shipped Nintendo fallback icon instead of overstating full brand-icon coverage |
| 2026-06-07 | Social row behavior | Documented that connected manual socials now prioritize their outbound action on tap while preserving an explicit secondary edit affordance | Keeps the maintained profile contract aligned with the corrected Xbox / PlayStation / Nintendo row behavior after the audit follow-through |
| 2026-06-07 | Provider visuals | Documented the maintained shared provider icon treatment for `Connected Accounts` and `Socials`, including branded `line_icons` glyphs and provider-tinted standalone icons | Keeps the written profile UI contract aligned with the shared provider visual system now used across auth and profile surfaces |
| 2026-06-07 | Social row behavior | Clarified that mirrored official socials in the `Socials` section are read-only, visually match other socials, and open external provider profiles only when a usable profile URL exists | Aligns the maintained profile contract with the intended tap behavior for Steam and Discord socials |
| 2026-06-07 | Profile rendering | Split provider identity rendering into separate `Connected Accounts` and `Socials` sections, with Steam/Discord mirrored into the social view and manual platforms managed there | Keeps the profile UX aligned with the intended distinction between login linkage and social presence |
| 2026-06-07 | Scope, field notes, and profile rendering | Added the profile-side contract for linked provider identities and clarified that app profile fields remain separate from social-platform identities | Keeps the profile spec aligned with the new normalized provider-identity model and connected-accounts UI |
| 2026-06-04 | Spec topology | Created a dedicated profiles spec by extracting user-profile, avatar, onboarding-profile, and edit-profile contracts from the larger SP1 core-platform spec | Keeps the most frequently changing SP1 surface focused and easier to maintain |
| 2026-06-04 | Avatar failure contract | Added the maintained avatar-upload error-code surface for invalid file types, oversize uploads, and temporary storage unavailability | Keeps the profile/avatar API contract aligned with the implemented backend responses and localized Flutter error handling |
| 2026-06-04 | Web avatar upload flow | Clarified that mobile sources are cropped before upload while the web picker currently uploads validated original bytes directly and depends on storage CORS | Keeps the spec aligned with the implemented cross-platform avatar editor behavior and deployment requirements |
| 2026-06-04 | Avatar editor spike | Documented the hybrid follow-through where `Upload photo` uses a shared square editor on iOS/Android/Web while mobile library/camera sources keep the existing native crop flow | Captures the evaluated migration step without claiming a full replacement of every avatar acquisition path |
| 2026-06-04 | Unified avatar editor flow | Updated the maintained contract so every supported image source routes through the shared square editor, tapping an existing avatar reopens it for editing, and URL input now fetches/crops/uploads instead of storing external URLs directly | Aligns the profile/avatar spec with the implemented cross-platform editor-centered behavior |
| 2026-06-04 | Storage topology | Added the maintained MinIO-backed local dev path, clarified that release compose now bundles MinIO by default for self-hosted installs, and documented the split between internal storage endpoints and browser-facing upload hosts when needed | Documents the now-supported self-hosted storage path without changing the user-profile API surface |
| 2026-06-04 | Onboarding timezone parity | Added the onboarding contract note that profile setup now reuses the shared timezone selector from profile editing and persists the chosen value before completion | Keeps onboarding and profile editing aligned on the same timezone capture UX and saved profile data |
