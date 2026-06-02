---
spec: core-platform
version: "2.37"
status: complete
last_updated: "2026-06-03"
sub_project: 1
---

# InGame -- Core Platform Design Spec

> Part of the [InGame Product Roadmap](roadmap.md)

## Overview

InGame is a social gaming coordination app that makes it easy to find time to play video games with friends. The core problem: it's hard to align gaming time with friends due to missed communication and random availability windows. InGame solves this by letting users create groups of friends where anyone can signal they're "ready to game," notifying the entire group instantly.

This spec covers **Sub-Project 1: Core Platform** -- the foundational layer that all other features build on. See the [roadmap](roadmap.md) for the full sub-project breakdown and dependency graph.

---

## Target Platforms

- iOS (App Store)
- Android (Play Store)
- Web

---

## Tech Stack

### Frontend
- **Flutter 3.44 / Dart 3.12** -- cross-platform UI
- **Riverpod** -- state management and dependency injection
- **GoRouter** -- declarative routing with deep linking and auth guards
- **freezed** -- immutable domain models with copyWith, pattern matching
- **flutter_secure_storage** -- secure token persistence (iOS/Android); on web, falls back to `SharedPreferences` (localStorage) since `flutter_secure_storage` is unreliable in browsers
- **flutter_web_auth_2** -- OAuth browser flows (Steam OpenID 2.0 callback handling)
- **sign_in_with_apple** -- Apple Sign-In (iOS/macOS native, web JS-based)
- **dio** -- HTTP client used by the handwritten Flutter repositories
- **cue** -- physics-first animation library for future transitions, motion systems, and reusable animation scenes
- **flutter_localizations + intl + gen_l10n** -- official Flutter localization stack with generated `AppLocalizations` and English/German ARB catalogs

### Backend
- **FastAPI (Python)** -- async REST API + WebSocket server
- **PostgreSQL 16** -- persistent relational data
- **Redis 7** -- real-time state, sessions, pub/sub
- **SQLAlchemy (async)** -- ORM with Alembic migrations
- **Pydantic v2** -- request/response validation (source of truth for OpenAPI spec)
- **JWT** -- access tokens (15 min) + refresh tokens (30 days, Redis-stored)
- **bcrypt** -- password hashing

### DevOps
- **Docker Compose** -- local development (PostgreSQL + Redis + API)
- **OpenShift + ArgoCD** -- production deployment (apps-of-app pattern, leveraging ocp-gitops)
- **CI/CD** -- lint, test, build images, validate OpenAPI contract

### Monorepo Structure
```
ingame/
  lib/                           # Flutter app
  backend/                       # FastAPI backend
  build.yaml                     # json_serializable config (snake_case field rename)
  docker-compose.yml             # Local dev stack
  deploy/                        # Helm charts / Kustomize for OpenShift
  scripts/
    generate-api-client.sh       # OpenAPI -> Dart codegen
    ci/                          # CI validation scripts
```

---

## System Architecture

```
Flutter Clients (iOS, Android, Web)
    |                        |
    | REST (HTTPS)           | WebSocket (WSS)
    v                        v
FastAPI Server (single process, REST + WS endpoints)
    |           |            |
    v           v            v
PostgreSQL    Redis       External Services
(users,       (sessions,  (Steam OAuth,
 groups,       status,     Apple Sign-In,
 memberships)  pub/sub)    Push: FCM/APNs)
```

- Single FastAPI server handles both REST and WebSocket
- All Flutter clients share the same codebase and connect to the same API
- Redis pub/sub powers real-time: status change -> publish to Redis channel -> WebSocket server fans out to connected group members
- Push notifications (FCM/APNs) for offline users
- JWT-based auth with refresh tokens in Redis

---

## Authentication

### Supported Methods
- **Email/password** -- standard registration and login
- **Steam OAuth** -- OpenID 2.0 (Steam's auth mechanism)
- **Apple Sign-In** -- required for iOS App Store (guideline 4.8) when social login is offered

### Auth Flow
1. User registers or logs in via email/password, Steam, or Apple
2. Backend validates credentials, creates/finds user record in PostgreSQL
3. Backend issues JWT access token (15 min) + refresh token (30 days)
4. Refresh token stored in Redis (bound to user ID)
5. Flutter stores tokens via `SecureStorageService` (platform-aware: `flutter_secure_storage` on native, `SharedPreferences` on web)
6. Dio interceptor attaches access token to all API requests
7. On 401, interceptor attempts token refresh; if refresh fails, redirect to login

### Recovery Email Requirement
- Every account must finish onboarding with an email address on file for recovery and account communication.
- If the initial auth method exposes an email address (email/password registration, Apple Sign-In), onboarding shows the email field beneath display name and pre-populates it from auth.
- If the initial auth method does not expose an email address (currently Steam OpenID), onboarding requires the user to enter one manually before completion.
- The onboarding email field follows the same uniqueness validation rules as registration email entry.
- Onboarding persists that recovery email through `PATCH /api/v1/users/me` alongside the other profile-step fields; the backend enforces the same uniqueness rule as registration while keeping `has_password_login=false` unless `POST /api/v1/users/me/set-email-password` is used.
- Having a recovery email on file does not imply password login is enabled; social-auth users may still add a password later from profile settings.

### Availability Checks
Before submitting registration, the frontend validates uniqueness of email and display name via debounced async calls:
- `POST /api/v1/auth/check-email` -- body: `{"value": "..."}`, returns `{"available": true/false}`
- `POST /api/v1/auth/check-display-name` -- body: `{"value": "..."}`, returns `{"available": true/false}`

Display name comparison is case-insensitive.

### Account Linking
Users who register with email can later link Steam or Apple accounts in profile settings. Social-auth users keep a recovery email on file from onboarding (auth-provided when available, otherwise manually entered) and can add a password later via profile settings to enable email/password login as an alternative. Linking is always explicit and user-initiated.

**Backend endpoints:**
- `POST /api/v1/users/me/link-steam` -- validates Steam OpenID params, checks no conflict, sets `steam_id`
- `POST /api/v1/users/me/link-apple` -- validates Apple identity token, checks no conflict, sets `apple_id`
- `DELETE /api/v1/users/me/link-steam` -- clears `steam_id`
- `DELETE /api/v1/users/me/link-apple` -- clears `apple_id`

Conflict detection: if another user already has the target `steam_id` or `apple_id`, the link returns 409.

**Add email/password (social-only users):**
- `POST /api/v1/users/me/set-email-password` -- body: `{"email": "...", "password": "..."}`. Sets `email` + `password_hash` on the user. Returns 409 if user already has email/password or if email is taken by another user. Flutter shows a dialog from the Connected Accounts card.
- User-facing auth responses and `GET /users/me` include `has_password_login`, derived from whether `password_hash` is present. Flutter uses that explicit flag for the `Email & Password` connected-state instead of inferring it from `email`.

**Lockout guard:** Unlinking Steam or Apple is rejected with 422 if it would remove the user's only login method. The backend counts auth methods (`email+password`, `steam_id`, `apple_id`) and requires at least 1 to remain after unlinking.

**Revoked provider lifecycle:** Unlinking Steam or Apple also writes a durable revoked-provider record keyed by `{provider, external_id}`. Future direct provider login with that same Steam/Apple identity is blocked with a relink-required error until the user signs in through another method and relinks the provider from profile. The current authenticated session remains valid after unlink; the revoke only affects future sign-in attempts with the removed provider.

**Flutter implementation:** The `OAuthLauncher` utility (`lib/features/auth/data/oauth_launcher.dart`) provides shared methods for both login and profile linking flows:
- `launchSteamAuth()` -- builds Steam OpenID URL, launches browser via `flutter_web_auth_2`, returns callback params
- `launchAppleSignIn()` -- launches Apple Sign-In, returns identity token. On web, passes `WebAuthenticationOptions` with `APPLE_SERVICE_ID` env and redirect URI.
- Profile's Connected Accounts card triggers these flows directly; on success calls the profile repository's link methods and refreshes both profile and auth providers
- The profile screen shows the email address in the Account section, while Connected Accounts treats `Email & Password` as a pure auth-method row whose state comes from `has_password_login`
- Connected Steam/Apple rows remain actionable while linked, show destructive education before unlink, and confirm that the current session stays active while future provider sign-ins are disabled until relinked
- Successful unlink now shows explicit localized success feedback, and last-method attempts surface a localized \"add another sign-in method first\" message instead of a generic validation error
- Steam unlink currently clears only the auth link; future Steam-backed features (such as planned library sync) must gate on an active `steam_id` and remain unavailable until Steam is relinked
- OAuth/browser failures are mapped through locale-aware user-facing messages so login/profile linking flows do not fall back to inline English copy

**Platform callback configuration:**

| Platform | Steam callback | Apple Sign-In | Config file(s) |
|----------|---------------|---------------|----------------|
| **iOS** | `ingame://auth/steam/callback` via `CFBundleURLTypes` | Native AuthenticationServices via `Runner.entitlements`, applied through the Runner target's `CODE_SIGN_ENTITLEMENTS` build setting | `ios/Runner/Info.plist`, `ios/Runner/Runner.entitlements`, `ios/Runner.xcodeproj/project.pbxproj` |
| **Android** | `ingame://` scheme via `CallbackActivity` intent filter | N/A (Apple Sign-In not on Android) | `android/app/src/main/AndroidManifest.xml` |
| **Web** | `{origin}/auth/steam-callback.html` static HTML page posts result via `window.opener.postMessage` and falls back to `localStorage` when opener state is unavailable | `{origin}/auth/apple-callback.html` + `WebAuthenticationOptions(clientId, redirectUri)` | `web/auth/steam-callback.html`, `web/auth/apple-callback.html` |
| **macOS** | `ingame://auth/steam/callback` via `CFBundleURLTypes` | Native AuthenticationServices via entitlements | `macos/Runner/Info.plist`, `macos/Runner/*.entitlements` |

- `flutter_web_auth_2` always receives the valid custom scheme `ingame`; on web that value is ignored and the flow resolves via `postMessage` from the callback HTML page
- Apple Service ID for web is configured via `--dart-define=APPLE_SERVICE_ID=com.ingame.web` at build time
- iOS now uses Flutter's generated Swift Package Manager plugin integration for app/runtime plugins; stale CocoaPods project wiring and Pod support-file includes were removed so native auth/build flows rely on the SPM-managed setup only

---

## Data Models

### PostgreSQL Tables

**User**
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| email | VARCHAR | Unique, nullable (Steam-only users) |
| password_hash | VARCHAR | Nullable (social-only users) |
| has_password_login | BOOLEAN | Derived response field; true when `password_hash` is present |
| display_name | VARCHAR | Required |
| avatar_url | VARCHAR | Nullable |
| bio | TEXT | Nullable |
| timezone | VARCHAR | e.g., "Europe/Berlin" |
| preferred_gaming_hours | JSONB | Weekly schedule, e.g., `{"monday": [{"start": "18:00", "end": "23:00"}]}` |
| steam_id | VARCHAR | Unique, nullable |
| apple_id | VARCHAR | Unique, nullable |
| created_at | TIMESTAMP | Auto-set |
| updated_at | TIMESTAMP | Auto-updated |

`preferred_gaming_hours` remains the recurring profile-availability field for SP1. It may be empty, can be captured coarsely during onboarding, and can later be refined per day from profile editing. It is intentionally distinct from any future game/genre preference model in SP3.

**RevokedAuthLink**
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK -> User that revoked the provider |
| provider | VARCHAR | `steam` or `apple` |
| external_id | VARCHAR | Provider subject / external account ID |
| revoked_at | TIMESTAMP | Auto-set |

**Group**
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| name | VARCHAR | Required |
| description | TEXT | Nullable |
| invite_code | VARCHAR | Unique, short alphanumeric (e.g., "XK7F2M") |
| is_discoverable | BOOLEAN | Default false |
| join_mode | VARCHAR | "open" (instant join) or "approval" (request to join); only relevant when is_discoverable=true. Default "open" |
| avatar_url | VARCHAR | Nullable |
| created_by | UUID | FK -> User |
| created_at | TIMESTAMP | Auto-set |
| updated_at | TIMESTAMP | Auto-updated |

**GroupMembership**
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK -> User |
| group_id | UUID | FK -> Group |
| role | VARCHAR | "owner" / "admin" / "member" |
| joined_at | TIMESTAMP | Auto-set |
| Unique constraint | | (user_id, group_id) |

### Group RBAC

Group roles are part of the Core Platform contract and use three levels:

| Role | Purpose |
|------|---------|
| `owner` | Final authority for the group; can manage admins and destructive group actions |
| `admin` | Trusted manager for day-to-day group administration without ownership transfer or destructive ownership-only powers |
| `member` | Standard participant in the group |

#### Action Matrix

| Action | Owner | Admin | Member |
|--------|-------|-------|--------|
| View group details and members | Yes | Yes | Yes |
| Open/share invite UI | Yes | Yes | Yes |
| Leave group | Yes, unless ownership transfer/delete is required first | Yes | Yes |
| Edit name / description / avatar | Yes | Yes | No |
| Change discoverability / join mode | Yes | Yes | No |
| View pending join requests | Yes | Yes | No |
| Approve / deny join requests | Yes | Yes | No |
| Remove non-owner members | Yes | Yes | No |
| Promote member to admin | Yes | No | No |
| Demote admin to member | Yes | No | No |
| Transfer ownership | Yes | No | No |
| Delete group | Yes | No | No |

#### Enforcement Notes
- Backend authorization is the source of truth; Flutter must mirror the same matrix to avoid presenting unavailable actions.
- Settings and moderation screens should only expose actions available to the current member role.
- Owner-only actions stay owner-only even if an admin can see most group-management surfaces.
- Group membership is the minimum requirement for reading member-scoped group surfaces; non-members should not be treated as if they have read access to private group details just because they are authenticated.

#### RBAC Endpoint Contract
- `PATCH /api/v1/groups/{group_id}/members/{user_id}/role` -- owner-only role change between `admin` and `member`; cannot be used on the current owner. Returns 204.
- `POST /api/v1/groups/{group_id}/transfer-ownership` -- owner-only ownership transfer with body `{"user_id": "..."}`. The target must already be a non-owner member. On success, the target becomes `owner` and the previous owner is demoted to `admin`. Returns 204.
- `DELETE /api/v1/groups/{group_id}/leave` -- self-leave endpoint aligned with Flutter's leave-group flow. Returns 204 for admin/member self-leave, and 403 `group.owner_cannot_leave` while the caller is still the owner.
- `DELETE /api/v1/groups/{group_id}/members/{user_id}` remains the remove-member route for owner/admin moderation of other non-owner members.

**JoinRequest**
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK -> User (the requester) |
| group_id | UUID | FK -> Group |
| status | VARCHAR | "pending" / "approved" / "denied" |
| created_at | TIMESTAMP | Auto-set |
| resolved_by | UUID | FK -> User (admin/owner who resolved), nullable |
| resolved_at | TIMESTAMP | Nullable |
| Unique constraint | | (user_id, group_id) where status="pending" |

### API Response Shapes (Pydantic → Flutter)

These are the Pydantic response schemas that define the API contract. Flutter Freezed models must match these shapes (not the raw DB tables).

**GroupMemberResponse** (returned by `GET /groups/{id}/members`)
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | Membership ID |
| user_id | UUID | FK -> User |
| display_name | String | Resolved from User |
| avatar_url | String? | Resolved from User |
| role | String | "owner" / "admin" / "member" |
| joined_at | DateTime | |

**JoinRequestResponse** (returned by `GET /groups/{id}/join-requests`)
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | Join request ID |
| user | Object | Nested: `{id, display_name, avatar_url}` |
| group_id | UUID | FK -> Group |
| status | String | "pending" / "approved" / "denied" |
| created_at | DateTime | |
| resolved_by | UUID? | Admin/owner who resolved |
| resolved_at | DateTime? | |

### Redis Structures (Ephemeral)
- `user:{id}:status` -- hash: `{state, game, since}` (`online`, `ready`, `away`, `offline`)
- `user:{id}:session` -- refresh token + session metadata
- `group:{id}:online` -- set of user IDs currently online
- Channel `group:{id}:events` -- pub/sub for real-time events

---

## Flutter App Architecture

### Pattern: Feature-First

```
lib/
  main.dart
  app.dart

  core/
    localization/
      locale_controller.dart         # Persisted locale preference + app localization access
      locale_aware_form_state_mixin.dart # Revalidates visible form errors after locale changes
    theme/
      app_theme.dart
      glass_components.dart          # GlassCard (with animate/animationDelay), GlassButton, GlassInput, etc.
      text_styles.dart
      spacing.dart                   # AppSpacing + AppBreakpoints (sidebar: 768)
    networking/
      api_client.dart
      websocket_client.dart
      api_endpoints.dart
      app_failure.dart              # Typed user-facing failure descriptors resolved in the UI
    routing/
      app_router.dart
      route_normalization.dart        # Canonicalizes auth redirect targets and strips stale query params
      route_names.dart
      page_transitions.dart          # adaptiveRoutePage (web fade/slide, native mobile pages)
    storage/
      secure_storage.dart
      preferences.dart
    utils/
      extensions.dart
      validators.dart

  generated/                         # Reserved for optional future generated artifacts

  l10n/
    app_en.arb
    app_de.arb
    app_localizations.dart

  features/
    auth/
      data/
        auth_repository.dart
        oauth_launcher.dart           # Shared Steam/Apple OAuth flow (used by login + profile linking)
      domain/
        user_model.dart              # Freezed domain model
        auth_state.dart              # Auth state + typed AppFailure payload for error state
      presentation/
        providers/
          auth_provider.dart         # Riverpod AsyncNotifier
        screens/
          login_screen.dart
          register_screen.dart
          steam_auth_screen.dart
        widgets/
          auth_form.dart
          social_login_buttons.dart

    onboarding/
      presentation/
        providers/
          onboarding_provider.dart   # needsOnboardingProvider (checks recovery email + bio; recurring availability is optional)
        screens/
          onboarding_screen.dart     # 3-page PageView wizard (Welcome, Profile Setup, Gaming Preferences)

    profile/
      data/
        profile_repository.dart      # Includes linkSteam/linkApple/unlinkSteam/unlinkApple methods
      domain/
        profile_model.dart
      presentation/
        providers/
          profile_provider.dart
        screens/
          profile_screen.dart        # Connected accounts card with interactive link/unlink
          edit_profile_screen.dart
        widgets/
          avatar_picker.dart
          gaming_hours_editor.dart
          timezone_selector.dart

    groups/
      data/
        groups_repository.dart
      domain/
        group_model.dart
        membership_model.dart
      presentation/
        providers/
          groups_provider.dart
          group_detail_provider.dart
        screens/
          groups_list_screen.dart
          group_detail_screen.dart
          create_group_screen.dart
          join_group_screen.dart
          group_directory_screen.dart
          group_settings_screen.dart
        widgets/
          group_card.dart
          member_list.dart
          invite_link_share.dart

  shared/
    widgets/
      glass_app_bar.dart
      glass_bottom_nav.dart
      adaptive_shell.dart            # Responsive shell: bottom nav (<768px) or glass sidebar (>=768px)
      ingame_logo.dart               # Reusable brand logo: gradient icon + gradient text, 3 sizes (small/medium/large), optional tagline
      tappable.dart                   # Reusable MouseRegion+GestureDetector wrapper; auto pointer cursor on desktop/web
      app_toast.dart                  # Shared glass-styled toast/snackbar system for success, error, info, warning feedback
      status_indicator.dart          # UserStatus enum + pulsing dot indicator
      loading_indicator.dart
      error_display.dart
      user_avatar.dart
      language_switcher.dart         # Shared compact/settings locale switcher
    providers/
      connectivity_provider.dart
      websocket_provider.dart
```

### Key Patterns
- Each feature has `data/`, `domain/`, `presentation/` subdirectories
- Providers (Riverpod) live in `presentation/providers/`
- Repositories in `data/` call handwritten Dio endpoints and map JSON payloads to freezed domain models
- Domain models are freezed classes (immutable, copyWith, pattern matching)
- `core/` is the shared foundation; `shared/` holds cross-feature widgets
- User-facing Flutter copy is localized through generated `AppLocalizations`; widgets use `context.l10n`, while non-widget helpers (e.g. validators / API error mappers) use a locale-aware fallback accessor
- The maintained localization sweep covers shared widgets, auth/onboarding/group/profile flows, and supporting validator/error/helper copy so user-visible inline English does not drift back into the app
- User-visible failures that survive rebuilds are modeled as typed `AppFailure` values instead of already-localized strings, and widgets resolve the current text from `context.l10n` at display time.
- Form screens with visible validation output re-run validation after a locale change, while untouched forms stay quiet until the user interacts.
- If generated API code is reintroduced later, treat it as read-only and never manually edit it

### API Contract Pipeline
1. Backend defines Pydantic schemas (single source of truth)
2. FastAPI auto-generates OpenAPI spec at `/api/v1/openapi.json`
3. Flutter repositories consume that contract through handwritten Dio calls and matching freezed/domain models
4. CI validates backend/frontend contract alignment and spec freshness

---

## Backend Architecture

```
backend/
  app/
    main.py
    config.py

    api/v1/
      router.py
      auth/
        routes.py, schemas.py, service.py
      users/
        routes.py, schemas.py, service.py
      groups/
        routes.py, schemas.py, service.py
      join_requests/
        routes.py, schemas.py, service.py

    ws/
      manager.py, handlers.py, events.py

    db/
      database.py
      models/
        user.py, group.py
      repositories/
        user_repo.py, group_repo.py
      migrations/

    redis/
      client.py, status_store.py, pubsub.py

    auth/
      jwt.py, dependencies.py, steam.py, apple.py, password.py

    core/
      exceptions.py, middleware.py

  tests/
    conftest.py
    api/
      test_auth.py, test_users.py, test_groups.py
    ws/
      test_websocket.py

  alembic.ini
  requirements.txt
  Dockerfile
```

### Key Patterns
- API versioning (`/api/v1/`) from the start
- Service layer between routes and repositories (business logic lives in services)
- Async throughout: async SQLAlchemy, aioredis, async FastAPI
- Pydantic v2 schemas for all request/response validation
- `get_current_user` FastAPI dependency for protected routes
- Custom app HTTP exceptions carry a stable machine-readable `code` alongside human-readable `detail`, and `main.py` serializes those responses centrally for Flutter consumers.
- Alembic for database migrations

---

## Design System: Glassmorphism

### Color Palette
- **Background**: Deep dark gradient (`#0A0E1A` to `#151B2E`)
- **Glass surfaces**: `rgba(255, 255, 255, 0.05-0.15)` with `BackdropFilter` blur (10-20px)
- **Primary accent**: Electric blue (`#4FC3F7`)
- **Secondary accent**: Purple (`#B388FF`)
- **Success/Ready**: Vivid green (`#69F0AE`)
- **Text**: White primary, 70% white secondary, 40% white tertiary

### Core Components
- **GlassCard** -- translucent container, backdrop blur, subtle border, rounded corners. Supports `animate: true` for Cue-backed fade+scale entry with staggerable `animationDelay`; public API stays `GlassCard(animate:, animationDelay:)`.
- **GlassAppBar** -- translucent app bar, blurs scrolling content behind it
- **GlassBottomNav** -- frosted bottom navigation with active indicator glow (mobile only)
- **GlassButton** -- primary/secondary/ghost variants, glow effect on primary
- **GlassInput** -- translucent input with fill color and focus glow (no `BackdropFilter` -- avoids clipping floating labels)
- **StatusIndicator** -- glowing dot (green/gray/amber) with Cue-backed pulse animation for `ready` status. Public API remains `StatusIndicator(status:, size:, showPulse:)`, with the implementation split into a static dot layer and a dedicated ready-pulse ring. Enum: `ready`, `online`, `away`, `offline`.
- **AvatarWithStatus** -- user avatar with StatusIndicator overlay
- **InGameLogo** -- reusable brand widget: gradient-filled icon container + gradient `ShaderMask` text. Three sizes (`small`, `medium`, `large`) with proportional scaling. Optional `showTagline` for the login screen. Used in login header, sidebar header, and anywhere brand identity is needed.
- **SocialLoginButtons** -- platform-authentic login buttons: Steam button uses Steam's brand palette (navy gradient `#2A475E`→`#1B2838`, blue border/glow `#66C0F4`, hover states); Apple button uses Apple HIG style (white/light gray `#F5F5F7` background, black text/icon). Hover emphasis is driven by `Cue.onHover` instead of manual hover state wiring.
- **AppToast** -- shared glass-styled feedback overlay with translucent dark surface, accent strip/icon by severity, rounded corners, and consistent floating placement. Exposes `success`, `error`, `info`, and `warning` helpers; used instead of raw `SnackBar(...)`. Renders on the root overlay and animates with Cue-driven fade + subtle upward slide on show/hide.
- **AdaptiveShell** -- responsive navigation shell: GlassBottomNav on mobile, glassmorphism sidebar (220px) on tablet/desktop

### Interaction Conventions
- **Pointer cursor**: All tappable elements show `SystemMouseCursors.click` on desktop/web hover. Use the `Tappable` widget (`shared/widgets/tappable.dart`) instead of raw `GestureDetector` — it wraps `MouseRegion` + `GestureDetector` with automatic cursor handling. Built into `GlassCard`, bottom nav items, and sidebar items via `Tappable`. `GlassButton` uses a raw `MouseRegion` since its inner `ElevatedButton`/`OutlinedButton`/`TextButton` handles its own taps. Hover-tracking widgets (e.g., social login buttons with animated hover states) use `Cue.onHover`, which provides the pointer cursor and motion trigger together. Enforced by `.cursor/rules/pointer-cursor.mdc`.
- **Root-level overlays**: All `showModalBottomSheet` and `showDialog` calls inside shell routes must use `useRootNavigator: true` so they render above the persistent navigation bar/sidebar, not beneath it.
- **Localized copy only**: New user-facing Flutter strings must be added through `lib/l10n/app_en.arb` and `lib/l10n/app_de.arb`, then referenced via generated localization accessors. This includes shared widget copy plus validator, toast, dialog, and error/helper text that reaches users. German catalog updates should prefer natural `ä`, `ö`, `ü`, and `ß` forms when linguistically correct. This is enforced by `.cursor/rules/localize-user-facing-strings.mdc`.
- **Locale behavior**: The app resolves locale from the system by default, persists manual overrides in shared preferences, and exposes a shared language switcher on the login screen and in profile preferences.
- **Popup menus**: `ThemeData.popupMenuTheme` is customized globally so overflow menus match the glassmorphism surface styling instead of default Material gray menus.

### Animation Principles
- **Page transitions**: platform-aware by default. Web can keep richer custom transitions such as `fadeSlideTransition`, while iOS and Android should preserve native push/pop behavior and native back/drag gestures for in-app navigation
- **StatusIndicator pulse**: Cue-driven 1500ms ease-in-out loop for `ready` state, with expanding ring + glow while preserving static rendering for other statuses
- **GlassCard entry**: optional Cue-driven fade+scale-in (350ms, from 96% scale), staggerable via `animationDelay`
- **Cue motion surfaces (first pass)**: Cue now powers app-root debug tooling, `GlassCard` entry, `AppToast` show/hide, social login hover emphasis, onboarding step-indicator transitions, onboarding time-slot selection motion, and `StatusIndicator` ready-pulse motion
- **Deferred from first Cue pass**: custom GoRouter page-transition polish on web and `GlassButton` disabled opacity remain on their current implementations until a later motion pass
- Smooth transitions on state changes throughout

### Responsive Layout
- **Mobile (<768px)**: single column, bottom navigation via `GlassBottomNav`
- **Tablet/Desktop (>=768px)**: glass sidebar navigation (220px), no bottom nav
- `AdaptiveShell` in `StatefulShellRoute` switches layout based on `LayoutBuilder` width
- Breakpoint constant: `AppBreakpoints.sidebar = 768`

---

## User Flows (Core Platform)

### Flow 1: First-Time User
Open app -> Welcome screen -> Register (email, Steam, or Apple) -> Onboarding wizard (3-step PageView: Welcome, Profile Setup, Recurring Availability) -> Home (groups list)

**Onboarding profile step:** The Profile Setup step contains display name followed by email. If auth already provided an email, the field is prefilled and editable. If auth did not provide one, the field is blank and required before the user can finish onboarding so every account has a recovery email. The email field reuses the same frontend validation and availability checks as registration.

**Onboarding recurring availability step:** The third step captures optional recurring availability preferences. It can stay empty without blocking onboarding completion. When present, onboarding may use coarse time-slot presets; edit profile remains the place to refine availability per day.

**Onboarding redirect:** GoRouter checks `needsOnboardingProvider` after auth. If the user lacks a recovery email or bio, they're redirected to `/onboarding`. Recurring availability no longer blocks completion. If onboarding interrupted another destination such as `/join/:code`, the router preserves that `from` target and restores it once onboarding is complete. `OnboardingScreen` also exits immediately once onboarding is no longer required, so users are not left stranded on `/onboarding`.

**Redirect normalization:** Auth/onboarding redirect carriers normalize their route locations and preserve only the whitelisted `from` query so stale or nested auth query params do not leak into later navigation.

**Intentional logout:** Manual logout from an authenticated screen goes to a clean `/login` route without preserving a stale `from` target such as `/profile`. Preserved `from` targets are reserved for interrupted protected/deep-link flows, not explicit sign-out.

### Flow 2: Create a Group
Home -> "Create Group" -> Enter name, description, avatar -> Choose visibility (private/discoverable) -> If discoverable, choose join mode (open/approval) -> Group created -> Share invite link

### Flow 3: Join via Invite Link
Receive link (`https://in-game.app/join/{code}`) -> Native app opens directly when installed via Universal Links / App Links, otherwise browser falls back to web -> App/web shows focused join screen -> If auth/onboarding is required, preserve the join target through those flows -> Backend previews group metadata by invite code -> "Join" -> Groups list refreshes -> Group detail view

### Flow 4: Join via Directory
Home -> "Discover" tab -> Browse/search groups (excludes groups user is already a member of) -> Preview -> Join instantly (if group allows open join) or Request to Join (if group requires approval; admin/owner approves or denies)

**Join request approval flow:** Group Settings screen shows a "PENDING REQUESTS (N)" section between MEMBERS and DANGER ZONE. Each request shows the user avatar, display name, relative timestamp, and approve (green) / deny (red) buttons. Deny prompts a confirmation dialog. Resolving a request auto-refreshes the group detail. A badge on the Settings menu item indicates pending request count.

**RBAC note:** Pending-request moderation belongs to owners and admins only. Regular members may still browse the group but should not see moderation controls.

### Flow 5: View Group & Members
Home -> Tap group card -> Group detail (member list, group info chips)

### Group Detail Screen Actions
The group detail app bar has a three-dot overflow menu (`more_vert`) with:
- **Invite** -- opens a bottom sheet containing the `InviteLinkShare` card (invite code display + copy/share buttons)
- **Settings** -- navigates to `GroupSettingsScreen` (edit name/description, toggle discoverability/join mode, manage members, delete group)
- **Leave Group** -- confirmation dialog, then removes membership and navigates back

**RBAC note:** The app bar menu is role-aware. Invite and Leave stay available to all members. Settings remains reachable only when the user has at least one settings action available, and the screen itself must show only the controls allowed by the current role.

### Navigation Structure

**Hybrid persistent navigation:** The sidebar/bottom nav stays visible for all browsable content. Focused task flows hide the nav to reduce distraction.

**Inside shell (nav persists):**
- Adaptive shell: bottom nav on mobile (<768px) | glass sidebar on tablet/desktop (>=768px)
- Tabs: Home (Groups List) | Discover (Directory) | Profile
- Groups branch (nested under `/`):
  - `/` → Groups list
  - `/groups/create` → Create group
  - `/groups/:id` → Group detail
  - `/groups/:id/settings` → Group settings
- Profile branch (nested under `/profile`):
  - `/profile` → Profile view
  - `/profile/edit` → Edit profile
- Navigation uses `goNamed` (not `pushNamed`) so routes resolve within the shell branch and maintain a back stack via `context.pop()`

**Outside shell (focused flows, no nav):**
- `/login` → Login screen
- `/register` → Registration screen
- `/steam-auth` → Steam OAuth flow
- `/join/:code` → Invite/deep-link join flow with group preview
- `/groups/join/:code` → legacy alias redirected to `/join/:code`
- `/onboarding` → First-time onboarding wizard
- If onboarding interrupts a deep link such as `/join/:code`, the router preserves `from` and returns there after completion

### Screen Count: ~12 screens

---

## Error Handling

- **Network errors**: Dio interceptor, non-intrusive snackbar with retry
- **Auth errors**: auto-refresh on 401, redirect to login if refresh fails, preserve deep-link return target when possible, and continue through onboarding before restoring the original destination
- **API errors**: business-rule failures return structured responses (`{"detail": "...", "code": "..."}`) and Flutter first maps them into typed `AppFailure` values before resolving localized user-facing copy
- **Request validation errors**: FastAPI/Pydantic request-shape validation keeps the default `422` body with `detail: [{loc, msg, ...}]`; Flutter formats those separately from business-rule error codes
- **WebSocket disconnection**: auto-reconnect with exponential backoff (1s -> 30s max)
- **Form validation**: inline field validation + backend validation as final gate; locale changes revalidate already-visible form errors so translated messages refresh immediately without waiting for the next submit

---

## Testing Strategy

### Flutter
- **Unit tests**: repositories, providers (Riverpod test utilities), domain model serialization, and focused realtime/networking helpers
- **Widget tests**: individual screens with mocked providers, form validation, locale-switch revalidation, and localization delegates enabled where migrated screens use `context.l10n`
- **Integration tests**: still planned for the highest-value end-to-end flows; current shipped coverage relies primarily on repository/provider/widget regression tests

### Backend
- **API tests**: auth, users, groups, join requests, and contract-sensitive business rules such as relink guards, recovery-email onboarding, and group RBAC
- **Realtime tests**: WebSocket auth, presence snapshots, ready fan-out, lifecycle transitions, expiry handling, and reconnect-ready restoration
- **Infrastructure**: async SQLite test DB, FakeRedis mock, and httpx AsyncClient with dependency overrides

### Cross-Cutting
- **API contract tests**: validate OpenAPI spec matches Flutter expectations
- **CI pipeline**: lint + test on PR, build images on merge to main

### Code Quality
- Dart: strict `analysis_options.yaml`
- Python: `ruff` linter, `mypy` type checking
- Pre-commit hooks for formatting and linting

---

## Deployment

### Local Development
Docker Compose: PostgreSQL 16 + Redis 7 + FastAPI API server, plus a dedicated static web container for Flutter web. The web container serves the built SPA and `/.well-known/*` verification files so invite links and native app-link validation can be exercised end-to-end in the same deployment shape used later in CI/CD images.

### Production
OpenShift cluster with ArgoCD apps-of-app pattern (leveraging existing `ocp-gitops` project). Separate Helm charts at `deploy/helm/ingame-api/` and `deploy/helm/ingame-web/` with Kustomize overlays at `deploy/kustomize/overlays/{dev,staging,prod}`. OpenShift Routes with TLS edge termination. PostgreSQL and Redis via operators or managed services.

**Invite links:** Production invite links use `https://in-game.app/join/:code`. The dedicated web runtime must serve `/.well-known/apple-app-site-association` and `/.well-known/assetlinks.json` on that same host so installed mobile apps open invite links natively before falling back to web. The Android asset links file must use the final release signing certificate fingerprint.

**Deploy directory structure:**
- `deploy/helm/ingame-api/` -- Helm chart for the FastAPI runtime (deployment, service, route, configmap, secret)
- `deploy/helm/ingame-web/` -- Helm chart for the static web runtime (deployment, service, route)
- `deploy/kustomize/base/` -- base Kustomization referencing Helm output
- `deploy/kustomize/overlays/dev/` -- 1 replica, debug, open CORS
- `deploy/kustomize/overlays/staging/` -- 2 replicas, staging host
- `deploy/kustomize/overlays/prod/` -- 3 replicas, strict CORS, production route

**Health endpoint:** `GET /health` returns `{"status": "ok"}` (used by deployment liveness/readiness probes).

### CI/CD Pipeline
1. On PR and main pushes: lint + test (Flutter + backend), validate OpenAPI contract, spec freshness check, and validate stack version alignment (`pubspec.yaml` vs backend/Helm metadata)
2. Release preparation happens on `dev`: bump `pubspec.yaml`, sync backend/Helm metadata and tracked deploy image refs to the same version, then merge that release-prepared commit into `main`
3. On release tag push from `main` (`vX.Y.Z`): validate the tag against the semver portion of `pubspec.yaml`, build and push `ghcr.io/<owner>/ingame-api` and `ghcr.io/<owner>/ingame-web`, and publish both semver and immutable SHA tags
4. A later GitOps phase may consume the already-committed tracked image refs for ArgoCD-driven rollout automation

---

## Change Log

| Date | Section | Change | Reason |
|------|---------|--------|--------|
| 2026-05-30 | Flutter App Architecture | Removed `auth_guard.dart` from routing | Auth guard logic consolidated into `app_router.dart` redirect |
| 2026-05-30 | Backend Architecture | Added `cors_allow_all` setting to `config.py` | Dynamic CORS for local dev (debug=true allows all origins) |
| 2026-05-30 | Monorepo Structure | Added `build.yaml` for json_serializable config | Backend returns snake_case JSON; Freezed models need `field_rename: snake` |
| 2026-05-30 | CI/CD Pipeline | Added spec freshness check to PR validation | Ensures spec is updated when API/model code changes |
| 2026-05-30 | Authentication | Added availability check endpoints (`check-email`, `check-display-name`) | Debounced async validation on register form before submission |
| 2026-05-30 | Flutter App Architecture | Added `api_error.dart` for user-friendly error mapping | Raw Dio errors were shown to users |
| 2026-05-30 | Tech Stack / Auth Flow | `SecureStorageService` is now platform-aware (native: `flutter_secure_storage`, web: `SharedPreferences`) | `flutter_secure_storage` throws `OperationError` on web, breaking all authenticated API calls |
| 2026-05-30 | Data Models | Added API Response Shapes section; documented `GroupMemberResponse` | Flutter `GroupMember` model had `timezone`/`isOnline` fields the API never returned, causing null deserialization crashes |
| 2026-05-30 | Design System | `GlassInput` no longer uses `BackdropFilter`/`ClipRRect` | `ClipRRect` clipped floating labels when field was focused or had text |
| 2026-05-30 | User Flows | Added "Group Detail Screen Actions" section | Group detail now uses overflow menu (invite sheet, settings, leave) instead of inline buttons |
| 2026-05-30 | User Flows / Backend | Discover endpoint excludes groups user is already a member of | Users could see and re-join their own groups in the directory |
| 2026-05-30 | Flutter App Architecture / User Flows | Added `GroupSettingsScreen` with route `/groups/:id/settings` | Owners/admins can edit group info, toggle visibility, manage members, delete group |
| 2026-05-30 | Authentication / Tech Stack | Implemented Steam OAuth Flutter flow via `flutter_web_auth_2` | Steam OpenID 2.0 browser flow with callback handling, `steamLogin` in auth provider |
| 2026-05-30 | Authentication / Tech Stack | Implemented Apple Sign-In Flutter flow via `sign_in_with_apple` | Apple button with platform guard (hidden on Android), `appleLogin` in auth provider |
| 2026-05-30 | Authentication / Backend | Added account linking endpoints (link/unlink Steam + Apple) | `POST/DELETE /users/me/link-{steam,apple}` with conflict detection |
| 2026-05-30 | Profile / Flutter | Interactive Connected Accounts card with link/unlink actions | Profile screen Steam/Apple rows now tappable with disconnect confirmation |
| 2026-05-30 | Groups / Flutter | Join request approval UI in GroupSettingsScreen | Pending requests section with approve/deny buttons, badge count on menu |
| 2026-05-30 | Groups / Data Models | Fixed `JoinRequest` Freezed model with nested `JoinRequestUser` | Backend returns `user` as nested object, not flat fields |
| 2026-05-30 | Onboarding / Flutter | 3-step onboarding wizard with GoRouter redirect | Welcome, Profile Setup, Gaming Preferences pages; redirect based on bio + gaming hours |
| 2026-05-30 | Design System / Flutter | Responsive `AdaptiveShell` replaces `ScaffoldWithNav` | Glass sidebar (220px) on wide screens, bottom nav on mobile; breakpoint 768px |
| 2026-05-30 | Design System / Flutter | Page transitions via `fadeSlideTransition` on GoRouter push routes | 300ms fade+slide for group detail, settings, create, edit profile routes |
| 2026-05-30 | Design System / Flutter | `GlassCard` supports `animate: true` with staggerable `animationDelay` | Fade+scale-in entry animation (350ms) for cards |
| 2026-05-30 | Design System / Flutter | `StatusIndicator` widget with pulse animation | UserStatus enum (ready/online/away/offline), pulsing ring for ready state |
| 2026-05-30 | Testing / Backend | 34 backend tests (auth, users, groups, WebSocket) | pytest + httpx AsyncClient + SQLite test DB + FakeRedis mock |
| 2026-05-30 | Backend | Added `GET /health` endpoint | Returns `{"status": "ok"}` for deployment probes |
| 2026-05-30 | Deployment | Created `deploy/` directory with Helm chart + Kustomize overlays | Helm templates for deployment/service/route/configmap/secret; overlays for dev/staging/prod |
| 2026-05-30 | Spec | Version 2.0 — Sub-Project 1 marked complete | All 10 audit gaps closed |
| 2026-05-30 | Onboarding / Flutter | Fixed onboarding finish: uses `ref.invalidate(authNotifierProvider)` | Calling `build()` directly didn't refresh auth state; GoRouter redirect looped back to onboarding |
| 2026-05-30 | Profile / Flutter | Gaming Hours card shows intelligent schedule display | Aggregates identical days ("Every day", "Weekdays", "Weekends"), renders time slots as labeled chips with icons |
| 2026-05-30 | Authentication / Flutter | Extracted `OAuthLauncher` shared utility; account linking fully wired | Login and profile linking flows share the same OAuth code; "coming soon" replaced with functional Steam/Apple linking |
| 2026-05-30 | Authentication / Backend | Added `POST /users/me/set-email-password` endpoint | Social-only users (Steam/Apple) can add email+password login to their account |
| 2026-05-30 | Authentication / Backend | Unlink lockout guard: rejects removing last auth method | Prevents users from locking themselves out by unlinking their only login method |
| 2026-05-30 | Profile / Flutter | Connected Accounts card shows Email row + set-email-password dialog | Three-row layout (Email, Steam, Apple) with full link/unlink/add flows |
| 2026-05-30 | Design System / Flutter | Added `InGameLogo` reusable brand widget (`shared/widgets/ingame_logo.dart`) | Consistent gradient branding across login screen and sidebar; replaces inline duplicated logo markup |
| 2026-05-30 | Design System / Flutter | Restyled `SocialLoginButtons` with platform-authentic styling | Steam button uses Steam brand palette with glow; Apple button follows Apple HIG white style; replaces generic `GlassButton` secondary variants |
| 2026-05-30 | Navigation / Flutter | Restructured routing for hybrid persistent navigation | Detail routes (group detail, settings, create, join, edit profile) moved inside `StatefulShellRoute` branches; sidebar/bottom nav stays visible during browsing; focused flows (auth, onboarding) remain outside shell; `pushNamed` → `goNamed` for in-shell navigation |
| 2026-05-30 | Design System / Flutter | Added pointer cursor convention for all tappable elements | `MouseRegion(cursor: SystemMouseCursors.click)` on GlassCard, GlassButton, sidebar items, bottom nav items, social buttons, text links, avatar picker, onboarding chips. Cursor rule at `.cursor/rules/pointer-cursor.mdc` |
| 2026-05-30 | Design System / Flutter | Root-level overlays: `useRootNavigator: true` on all bottom sheets and dialogs | With persistent nav, sheets/dialogs from branch navigators rendered beneath the nav bar; now they overlay everything correctly |
| 2026-05-30 | Design System / Flutter | Created `Tappable` reusable widget; replaced all raw `MouseRegion+GestureDetector` boilerplate | 8 instances of duplicated cursor+tap pattern consolidated into single `Tappable` widget. Used by GlassCard, sidebar items, bottom nav items, text links, avatar picker, onboarding chips. Hover-tracking widgets (social buttons) and GlassButton (internal Material buttons) remain as exceptions |
| 2026-05-30 | Authentication / Platform Config | Added OAuth callback configuration for all platforms | iOS: `CFBundleURLTypes` + `Runner.entitlements` (Apple Sign-In). Android: `CallbackActivity` intent filter. Web: explicit callback HTML files (`/auth/steam-callback.html`, `/auth/apple-callback.html`) + `WebAuthenticationOptions`. macOS: URL scheme + entitlements (network client + Apple Sign-In). `OAuthLauncher` uses the `ingame` custom scheme on native; on web it still passes `ingame`, but resolution happens through the callback page handoff while redirect URLs use `Uri.base.origin` |
| 2026-05-30 | Authentication / Web Fix | Fixed Steam web callback scheme handling, explicit callback files, and package-compatible handoff | `flutter_web_auth_2` rejected `Uri.base.origin` as `callbackUrlScheme` because it is not a valid RFC 3986 scheme. Web now passes the valid custom scheme `ingame`, while explicit static callback files (`/auth/steam-callback.html`, `/auth/apple-callback.html`) use the package’s expected `{ 'flutter-web-auth-2': window.location.href }` `postMessage` format and `localStorage` fallback when `window.opener` is unavailable. This avoids Flutter web dev/prod SPA fallback swallowing callback routes and handles browsers that lose popup opener state |
| 2026-05-30 | Design System / Flutter | Migrated first-pass shared motion surfaces to Cue | `CueDebugTools` enabled in debug builds; `GlassCard.animate`, `AppToast`, social login hover states, onboarding step indicator, and onboarding time-slot selection now use Cue while keeping existing public APIs and routing behavior intact |
| 2026-05-30 | Design System / Flutter | Migrated `StatusIndicator` pulse to Cue with split internals | `StatusIndicator` now composes a static `_StatusDot` with a Cue-powered `_ReadyPulseRing`, preserving `status/size/showPulse` API and adding a focused widget test for the ready-state Cue scene |
| 2026-05-30 | Design System / Flutter | Added shared `AppToast` component and replaced raw snackbars | Feedback now uses a single glass-styled toast system with severity-aware accents/icons and consistent floating placement. Direct `SnackBar(...)` usage was migrated across onboarding, profile, groups, and utility widgets to guarantee consistent themed feedback |
| 2026-05-30 | Design System / Flutter | Added fade/slide motion to `AppToast` | Toasts now render on the root overlay and animate in/out with fade plus subtle upward slide, instead of appearing/disappearing abruptly through the plain snackbar shell |
| 2026-05-30 | Animation / Tooling | Installed `cue` package and project-local `cue-animations` agent skill | `cue: ^0.3.1` added to `pubspec.yaml` for future physics-first animations. Installed `Milad-Akarie/cue` skill into `.agents/skills/cue-animations` so future animation work can follow Cue’s API/style guidance directly in this project |
| 2026-05-30 | Groups / Routing / Auth | Canonical invite flow moved to `/join/:code` with backend preview + post-auth return support | Invite links now target a focused join route, fetch preview metadata before join, keep `/groups/join/:code` as a legacy alias, and preserve deep-link destinations when auth refresh/login interrupts the flow |
| 2026-05-30 | Onboarding / Routing | Onboarding now exits to the preserved destination or home after profile completion | Fixes the remaining SP1 flow bug where users could finish onboarding but stay stranded on `/onboarding`, especially when onboarding interrupted a join deep link |
| 2026-05-31 | Invite Links / Platform Config | Added `in-game.app` native deep-link configuration scaffolding | Invite links now have a canonical public domain, iOS associated domains, Android App Links manifest wiring, and hosted `/.well-known/` files; Android release cert fingerprint still needs final replacement |
| 2026-05-31 | Deployment | Added a dedicated web deployment surface for Compose and OpenShift | The Flutter web app and `/.well-known/*` verification files are now expected to ship from a separate web image/runtime so future GHCR-tagged backend/frontend images can be deployed independently |
| 2026-05-31 | CI/CD Pipeline / Release Versioning | Added pubspec-driven release version contract and tag-triggered GHCR image publishing | `pubspec.yaml` is now the canonical stack release version, release prep aligns backend/Helm/deploy refs on `dev`, and release tags on `main` publish images from an already-aligned commit |
| 2026-05-31 | Deployment / Helm | Split the deployment charts into `ingame-api` and `ingame-web` | The API and web runtimes now have separate Helm ownership boundaries instead of one backend-branded chart containing both |
| 2026-05-31 | Flutter App Architecture / UX | Added official English/German localization foundation | Core app shell, validators, API errors, and high-traffic auth/onboarding/group/profile flows now use generated `AppLocalizations` instead of inline English copy |
| 2026-06-01 | Navigation / Flutter | Added route-aware query normalization for auth/onboarding redirects | Redirect carriers now keep only the canonical `from` target and strip stale nested query params that previously leaked across flows |
| 2026-06-01 | Localization / Flutter | Added system-locale default plus manual language switching on login/profile | Locale now follows system context until overridden, persists explicit language choice, and exposes a shared `LanguageSwitcher` on the first signed-out screen and in profile preferences |
| 2026-06-01 | Design System / Flutter | Added global popup menu theming and localized remaining high-traffic group/profile surfaces | Overflow menus now match the glass theme, and the connected-accounts/group management flows no longer fall back to inline English copy |
| 2026-06-01 | Authentication / Web | Restored `localStorage` fallback in Steam callback handoff for opener-less web flows | Steam web auth now matches the documented `flutter_web_auth_2` handoff contract instead of redirecting browser-only flows to the native custom scheme |
| 2026-06-01 | Navigation / Auth UX | Explicit logout now routes to clean `/login` without a preserved `from` query | Prevents stale return targets like `/profile` from lingering after intentional sign-out while keeping interrupted-flow redirects intact |
| 2026-06-01 | Localization / Spec Hygiene | Folded the full localization-sweep intent into the maintained core/roadmap specs | Keeps the lasting localization contract in tracked product docs instead of transient agent-planning files |
| 2026-06-01 | Error Handling / Flutter App Architecture | Added backend error codes, typed Flutter failures, and locale-aware form revalidation | Prevents frozen translated errors, removes raw exception text from key UI surfaces, and gives Flutter a stable machine-readable API error contract |
| 2026-06-01 | Release / SP1 Sign-Off | Marked SP1 complete for shipping at `v0.2.5` | Structured error handling and locale-aware validation were the final SP1 contract items before SP2 realtime work begins |
| 2026-06-01 | Release versioning | Retargeted unpublished release metadata from `v0.3.0` to `v0.2.5` | Keeps SP1 sign-off references aligned with the chosen patch-line cut before publish |
| 2026-06-02 | Authentication / Platform Config | Removed stale CocoaPods integration from iOS and aligned the project with Flutter's generated Swift Package Manager plugin setup | Eliminates Flutter's iOS SPM migration warning while keeping native Apple Sign-In entitlements/build wiring intact |
| 2026-06-02 | Authentication / Platform Config | Wired `Runner/Runner.entitlements` into the signed iOS Runner target build settings | Fixes device-side Apple Sign-In failures caused by the entitlements file existing in the repo without being applied to the built app |
| 2026-06-02 | Profile / Auth Contracts | Added `has_password_login` to user responses and decoupled email display from password-login state in profile | Prevents Apple/social accounts with an email but no password from being shown as if email/password login were already enabled |
| 2026-06-02 | Authentication / Onboarding | Required a recovery email during onboarding for all auth methods | Provider-supplied emails are prefilled, while provider flows without email exposure (currently Steam) must collect one manually before onboarding can finish |
| 2026-06-02 | Account Linking / Revoke Lifecycle | Added revoked-provider tracking, relink-required direct login guards, and destructive unlink UX semantics | Prevents unlinked Steam/Apple identities from silently creating duplicate accounts while making unlink consequences explicit and keeping current sessions intact |
| 2026-06-02 | Authentication / Onboarding / Users API | Made onboarding enforce and persist the recovery email contract through `PATCH /users/me` | Closes the remaining spec drift where Steam-style accounts could finish onboarding without an email on file |
| 2026-06-02 | Group RBAC / Onboarding / Navigation | Added an explicit owner-admin-member action matrix, made recurring availability optional during onboarding, and documented platform-aware page transitions that preserve native mobile gestures | Classifies the next SP1-owned feature batch before implementation and resolves terminology drift between recurring availability and future game preferences |
| 2026-06-02 | Group RBAC / Onboarding / Navigation | Implemented owner-only role-management endpoints, owner-leave guard semantics, optional onboarding availability completion, and adaptive mobile-vs-web route pages | Records the concrete SP1 completion contract now that the backend routes, Flutter gating, and router behavior are live |
| 2026-06-03 | Groups / Spec Hygiene / Testing | Enforced member-only access for private group detail/member reads, aligned the documented Flutter client architecture with handwritten Dio repositories, and updated testing strategy wording to match current coverage | Closes the largest SP1 audit drift and removes stale claims about generated clients, exact test counts, and integration-test coverage |
| 2026-06-03 | Users API Contract / CI | Added `has_password_login` to the `User` model table entry used by contract validation and kept revoked-provider fields scoped to `RevokedAuthLink` | Unblocks the API/spec validation job on `main` after the auth-method revoke and password-login-state work |
