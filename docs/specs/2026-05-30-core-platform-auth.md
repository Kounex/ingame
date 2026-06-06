---
spec: core-platform-auth
version: "1.7"
status: complete
last_updated: "2026-06-05"
sub_project: 1
---

# InGame -- Core Platform Auth Spec

> Part of the [InGame Product Roadmap](roadmap.md) and the [Core Platform overview](2026-05-30-core-platform-design.md)

## Scope

This spec covers the authentication and identity contract for SP1:
- sign-in methods
- tokens and session lifecycle
- recovery email requirements
- provider linking and unlinking
- platform callback configuration
- auth-specific business rules and failure behavior

## Supported Methods

- **Email/password** -- standard registration and login
- **Steam OAuth** -- OpenID 2.0 (Steam's auth mechanism)
- **Apple Sign-In** -- required for iOS App Store guideline 4.8 when social login is offered

## Auth Flow

1. User registers or logs in via email/password, Steam, or Apple.
2. Backend validates credentials and creates or resolves the user in PostgreSQL.
3. Backend issues a JWT access token (15 minutes) and refresh token (30 days).
4. Refresh token is stored in Redis and bound to the user session.
5. Flutter stores tokens via `SecureStorageService` (`flutter_secure_storage` on native, `SharedPreferences` on web).
6. A Dio interceptor attaches the access token to API requests.
7. On `401`, Flutter attempts refresh once; on refresh failure it clears local credentials and returns to login.

### Steam First-Login Dependency

Direct Steam sign-in validates the OpenID callback first, then fetches the Steam profile before creating a first-time account. If that profile lookup fails, the API returns a structured `503` business-rule response with code `auth.steam_profile_unavailable` instead of a raw `500`. Flutter maps that code to a locale-aware generic auth failure message rather than exposing backend English detail text directly.

## Auth-Related User Fields

| Field | Type | Notes |
|------|------|-------|
| `email` | string? | Required for email/password login; nullable for Steam-only users until onboarding/profile completion |
| `password_hash` | string? | Nullable for social-only users |
| `has_password_login` | bool | Derived response field; true when `password_hash` exists |
| `steam_id` | string? | Unique Steam external identity |
| `apple_id` | string? | Unique Apple external identity |

## Recovery Email Requirement

- Every account must complete onboarding with an email address on file for recovery and account communication.
- If the auth provider already exposes an email address (email registration, Apple Sign-In), onboarding pre-fills it and allows editing.
- If the auth provider does not expose one (currently Steam OpenID), onboarding requires manual email entry before completion.
- Onboarding persists the recovery email through `PATCH /api/v1/users/me`.
- A recovery email does **not** imply password login is enabled; social-auth users can still remain social-only until they explicitly add email/password login.

## Availability Checks

Before registration submission, Flutter validates uniqueness of email and display name through debounced async checks:

- `POST /api/v1/auth/check-email` -- body `{"value": "..."}` → `{"available": true|false}`
- `POST /api/v1/auth/check-display-name` -- body `{"value": "..."}` → `{"available": true|false}`

Display name comparison is case-insensitive.

## Account Linking

Users who register with email can later link Steam or Apple from profile settings. Social-auth users retain their recovery email from onboarding and may add password login later. Linking is explicit and user-initiated.

### Backend Endpoints

- `POST /api/v1/users/me/link-steam` -- validates Steam OpenID params, checks for conflicts, stores `steam_id`
- `POST /api/v1/users/me/link-apple` -- validates Apple identity token, checks for conflicts, stores `apple_id`
- `DELETE /api/v1/users/me/link-steam` -- clears `steam_id`
- `DELETE /api/v1/users/me/link-apple` -- clears `apple_id`
- `POST /api/v1/users/me/set-email-password` -- adds email/password login for social-only users

### Conflict Detection

If another user already owns the requested `steam_id` or `apple_id`, the link request returns `409`.

### Add Email/Password

- `POST /api/v1/users/me/set-email-password` accepts `{"email": "...", "password": "..."}`.
- It sets `email` and `password_hash` on the current user.
- It returns `409` if the account already has email/password login or if the email belongs to another user.
- Flutter uses `has_password_login` instead of inferring auth state from `email`.

### Lockout Guard

Unlinking Steam or Apple is rejected with `422` if it would remove the user's last available login method. The backend counts these auth methods:

- `email + password`
- `steam_id`
- `apple_id`

At least one must remain after unlink.

### Revoked Provider Lifecycle

Unlinking Steam or Apple also stores a durable revoked-provider record keyed by `{provider, external_id}`. Future direct login with that same provider identity is blocked until the user signs in with another method and relinks it from profile settings. The current authenticated session remains valid after unlink.

## Flutter Auth Integration

The shared `OAuthLauncher` utility (`lib/features/auth/data/oauth_launcher.dart`) provides the auth and linking flows:

- `launchSteamAuth()` -- builds Steam OpenID URL, launches the browser, returns callback params
- `launchAppleSignIn()` -- launches Apple Sign-In, returns an identity token; on web it uses `WebAuthenticationOptions`
- Apple availability in Flutter is shared between auth surfaces and profile linking: native Apple platforms may launch the native flow, while web only exposes Apple when `APPLE_SERVICE_ID` is configured for that build
- A missing Apple web service ID is treated as an unavailable local auth surface, not as a generic backend auth failure

Connected-account rows on the profile screen trigger these flows directly, then refresh both the profile and auth providers after success.

## Platform Callback Configuration

| Platform | Steam callback | Apple Sign-In | Config file(s) |
|----------|---------------|---------------|----------------|
| **iOS** | hosted `https://app.in-game.app/auth/steam-callback.html` page that bridges back to `ingame://auth/steam/callback` for the native auth session | Native AuthenticationServices via the app URL scheme | `ios/Runner/Info.plist`, `web/auth/steam-callback.html` |
| **Android** | `ingame://` scheme via `CallbackActivity` intent filter | N/A (Apple Sign-In not on Android) | `android/app/src/main/AndroidManifest.xml` |
| **Web** | `{origin}/auth/steam-callback.html` callback page resolves the browser flow | `{origin}/auth/apple-callback.html` + `WebAuthenticationOptions(clientId, redirectUri)` | `web/auth/steam-callback.html`, `web/auth/apple-callback.html` |

Additional constraints:

- The maintained SP1 auth callback contract covers the active product platforms only: iOS, Android, and Web.
- `flutter_web_auth_2` receives the valid custom scheme `ingame` for native Steam auth. The hosted Steam callback page adds an `ingame_native=1` bridge marker for native flows and redirects those sessions back into `ingame://auth/steam/callback`, while web still uses the callback HTML page messaging contract.
- Flutter runtime host defaults stay repo-local for development: `INGAME_API_BASE_URL=http://localhost:8000/api/v1`, `INGAME_WEB_APP_BASE_URL=http://localhost:8080`, and `INGAME_INVITE_BASE_URL=http://localhost:8080`.
- Native Steam callback generation uses `INGAME_WEB_APP_BASE_URL`, while invite/deep-link surfaces use `INGAME_INVITE_BASE_URL`.
- iOS associated domains remain required for invite links on `in-game.app`, but Steam auth no longer depends on a Universal Link association for `app.in-game.app`.
- Production native builds must pass explicit host `--dart-define` values rather than relying on repo defaults; the maintained iOS release path uses a dedicated `scripts/release/ios_prod.sh` wrapper, defaulting to `flutter run` and switching to `flutter build ipa` only when `--build` is provided.
- Apple web Sign-In uses `--dart-define=APPLE_SERVICE_ID=com.kounex.ingame.web` in the maintained CI/web-image build path.
- The release web image build must bake the Apple service ID at build time (for example through `Dockerfile.web` build args in GitHub Actions); this is not a runtime container env because Flutter web reads it through `String.fromEnvironment`.
- Backend Apple token verification must accept the configured list of Apple audiences (`INGAME_APPLE_CLIENT_IDS` or legacy `INGAME_APPLE_CLIENT_ID`) so native bundle IDs and the web service ID stay aligned with the shipped clients.
- Unsupported native platforms must not expose actionable Apple login or link affordances. Connected-account UI may still show an already-linked Apple identity so users can manage it.

## Auth Failure Contract

Key auth business-rule failures must continue to return stable machine-readable codes, including:

- `auth.invalid_credentials`
- `auth.refresh_token_invalid`
- `auth.refresh_token_revoked`
- `auth.steam_openid_invalid`
- `auth.steam_profile_unavailable`
- `auth.apple_token_invalid`
- `auth.steam_relink_required`
- `auth.apple_relink_required`
- `user.email_password_already_set`
- `user.last_auth_method_required`

Flutter maps these codes to locale-aware user-facing messages instead of parsing English response text.

## Change Log

| Date | Section | What changed | Why |
|------|---------|--------------|-----|
| 2026-06-06 | Platform config | Replaced the placeholder web Apple service ID with the maintained `com.kounex.ingame.web` identifier and documented that the web value must be baked into the CI-built Flutter web image instead of injected at container runtime | Keeps the written Apple web deployment contract aligned with the actual Flutter web build model and chosen Service ID |
| 2026-06-05 | Flutter auth integration and platform config | Added the shared Apple availability gate, documented the web-configured `APPLE_SERVICE_ID` requirement, and switched backend Apple verification to a configured audience list instead of a single client ID | Fixes the production web Apple mismatch and keeps login/link UI aligned with the actual supported runtime contract |
| 2026-06-04 | Spec topology | Created a dedicated auth spec by extracting auth and identity rules from the larger SP1 core-platform spec | Reduces spec size, merge conflicts, and update risk while keeping the auth contract focused |
| 2026-06-04 | Failure contract alignment | Corrected the refresh-token revoke code, documented the Steam first-login `503` fallback, and narrowed the maintained callback table to iOS/Android/Web | Keeps the written auth contract aligned with the implemented backend/client behavior and current platform scope |
| 2026-06-04 | Runtime host defaults | Clarified that Flutter runtime host defaults stay localhost for repo-independent development and that production native builds must pass explicit host defines | Prevents production domains from being hidden in the default repo config while keeping callback host behavior explicit |
| 2026-06-04 | iOS wrapper interface | Updated the maintained iOS production wrapper contract so `ios_prod.sh` defaults to `flutter run` and uses `--build` to produce an IPA | Keeps the documented production helper aligned with the implemented script behavior and interactive device testing workflow |
| 2026-06-04 | iOS Steam callback | Switched the maintained iOS Steam callback contract to the hosted `https://app.in-game.app/auth/steam-callback.html` Universal Link flow and documented the required associated-domain/AASA coverage | Prevents iOS production Steam sign-in from stalling on the callback page and being misread as a manual cancellation |
| 2026-06-04 | iOS Steam bridge fallback | Replaced the direct iOS HTTPS callback contract with a hosted-page bridge back into `ingame://auth/steam/callback` and removed the `app.in-game.app` auth-specific Universal Link dependency | Restores a more compatible native Steam auth flow after the direct iOS HTTPS callback path failed before presenting Steam on-device |
