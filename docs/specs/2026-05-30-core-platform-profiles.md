---
spec: core-platform-profiles
version: "1.5"
status: complete
last_updated: "2026-06-04"
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

## Avatar Contract

### Persistence Rule

- `avatar_url` remains the only persisted avatar field on the user.
- PostgreSQL stores only the final URL reference.
- Avatar bytes are **not** stored in the database or embedded as base64 in profile JSON.

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

### Storage Topology

- Local development composes in a self-hosted MinIO service, bootstraps the
  avatar bucket automatically, and enables MinIO browser-upload CORS so
  upload-init works out of the box.
- Release-style deployments may either point at any external S3-compatible
  storage service or opt into a bundled MinIO service when using the release
  compose stack for small self-hosted environments.
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

- rendering the current avatar preview
- opening the shared square editor when the current avatar is tapped
- presenting the source chooser separately through the `Change photo` action
- normalizing every supported source into the shared editor flow before upload
- local URL-entry validation
- upload progress display
- direct-to-storage upload orchestration through `AvatarUploadService`

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

## User Flows

### Onboarding

Flow:

`Welcome` -> `Profile Setup` -> `Gaming Preferences`

Profile setup requirements:

- display name is required
- recovery email is required before onboarding completion
- bio remains editable and can default to the shared onboarding fallback
- avatar is optional

The onboarding profile step uses the same avatar editor contract as profile editing.

### Edit Profile

The profile edit screen allows updates to:

- display name
- bio
- timezone
- avatar
- recurring availability

Changes are saved through `PATCH /api/v1/users/me`.

## Profile Rendering Contract

The profile screen:

- shows the avatar at the top
- shows email and timezone in the account section
- shows recurring gaming hours using an intelligent grouped display
- uses `has_password_login` for connected-account state

## Localization And UX Rules

- All user-facing copy for avatar flows lives in `lib/l10n/app_en.arb` and `lib/l10n/app_de.arb`
- Widgets use `context.l10n`
- Toasts, helper text, and dialog copy must not introduce inline English strings

## Change Log

| Date | Section | What changed | Why |
|------|---------|--------------|-----|
| 2026-06-04 | Spec topology | Created a dedicated profiles spec by extracting user-profile, avatar, onboarding-profile, and edit-profile contracts from the larger SP1 core-platform spec | Keeps the most frequently changing SP1 surface focused and easier to maintain |
| 2026-06-04 | Avatar failure contract | Added the maintained avatar-upload error-code surface for invalid file types, oversize uploads, and temporary storage unavailability | Keeps the profile/avatar API contract aligned with the implemented backend responses and localized Flutter error handling |
| 2026-06-04 | Web avatar upload flow | Clarified that mobile sources are cropped before upload while the web picker currently uploads validated original bytes directly and depends on storage CORS | Keeps the spec aligned with the implemented cross-platform avatar editor behavior and deployment requirements |
| 2026-06-04 | Avatar editor spike | Documented the hybrid follow-through where `Upload photo` uses a shared square editor on iOS/Android/Web while mobile library/camera sources keep the existing native crop flow | Captures the evaluated migration step without claiming a full replacement of every avatar acquisition path |
| 2026-06-04 | Unified avatar editor flow | Updated the maintained contract so every supported image source routes through the shared square editor, tapping an existing avatar reopens it for editing, and URL input now fetches/crops/uploads instead of storing external URLs directly | Aligns the profile/avatar spec with the implemented cross-platform editor-centered behavior |
| 2026-06-04 | Storage topology | Added the maintained MinIO-backed local dev path, clarified that release compose may optionally bundle MinIO, and documented the split between internal storage endpoints and browser-facing upload hosts when needed | Documents the now-supported self-hosted storage path without changing the user-profile API surface |
