---
spec: core-platform-auth
version: "2.16"
status: complete
last_updated: "2026-06-07"
sub_project: 1
---

# InGame -- Core Platform Auth Spec

> Part of the [InGame Product Roadmap](roadmap.md) and the [Core Platform overview](2026-05-30-core-platform-design.md)

## Scope

This spec covers the authentication and auth-provider contract for SP1:
- sign-in methods
- tokens and session lifecycle
- recovery email requirements
- provider linking and unlinking
- platform callback configuration
- auth-specific business rules and failure behavior

Social-connect identities that are not login providers are defined in [Core Platform Social Identities](2026-06-07-core-platform-social-identities.md).

## Supported Methods

- **Email/password** -- standard registration and login
- **Steam OAuth** -- OpenID 2.0 (Steam's auth mechanism)
- **Discord OAuth** -- OAuth 2.0 authorization code with PKCE
- **Apple Sign-In** -- required for iOS App Store guideline 4.8 when social login is offered

## Auth Flow

1. User registers or logs in via email/password, Steam, Discord, or Apple.
2. Backend validates credentials and creates or resolves the user in PostgreSQL.
3. Backend issues a JWT access token (15 minutes) and refresh token (30 days).
4. Refresh token is stored in Redis and bound to the user session.
5. Flutter stores tokens via `SecureStorageService` (`flutter_secure_storage` on native, `SharedPreferences` on web).
6. A Dio interceptor attaches the access token to API requests.
7. On `401`, Flutter attempts refresh once; on refresh failure it clears local credentials and returns to login.

### Steam First-Login Dependency

Direct Steam sign-in validates the OpenID callback first, then fetches the Steam profile before creating or refreshing the account-facing Steam identity. If the user's canonical `avatar_url` is still empty, the backend seeds it from the fetched Steam avatar; later Steam sign-ins do not overwrite an existing app-profile avatar. If the Steam profile lookup fails, the API returns a structured `503` business-rule response with code `auth.steam_profile_unavailable` instead of a raw `500`. Flutter maps that code to a locale-aware generic auth failure message rather than exposing backend English detail text directly.

### Discord Login Dependency

Discord sign-in uses an OAuth 2.0 authorization code flow with PKCE. The callback code and code verifier are exchanged for Discord tokens, then the backend fetches `/users/@me` to resolve the stable Discord user id plus current profile metadata before creating or refreshing the provider identity. If the user's canonical `avatar_url` is still empty, the backend seeds it once from the fetched Discord avatar; later Discord refreshes do not overwrite an existing app-profile avatar.

## Auth-Related User Fields

| Field | Type | Notes |
|------|------|-------|
| `email` | string? | Required for email/password login; nullable for pre-onboarding social-only users |
| `password_hash` | string? | Nullable for social-only users |
| `has_password_login` | bool | Derived response field; true when `password_hash` exists |
| `steam_id` | string? | Derived compatibility field while auth migrates to normalized provider identities |
| `apple_id` | string? | Derived compatibility field while auth migrates to normalized provider identities |

Auth-capable external identities are modeled durably through the provider-identity contract in [Core Platform Social Identities](2026-06-07-core-platform-social-identities.md). `steam_id` and `apple_id` may remain in API responses temporarily as derived helper fields while Flutter migrates.

## Recovery Email Requirement

- Every account must complete onboarding with an email address on file for recovery and account communication.
- If the auth provider already exposes an email address (email registration, Apple Sign-In, Discord when `email` scope is granted), onboarding pre-fills it and allows editing.
- If the auth provider does not expose one (currently Steam OpenID), onboarding requires manual email entry before completion.
- Onboarding persists the recovery email through `PATCH /api/v1/users/me`.
- After onboarding, Flutter treats `user.email` as the one canonical account email across all auth-capable flows and exposes a dedicated profile-level email-change surface for updating it.
- A recovery email does **not** imply password login is enabled; social-auth users can still remain social-only until they explicitly add email/password login.

## Availability Checks

Before registration submission, Flutter validates uniqueness of email and display name through debounced async checks:

- `POST /api/v1/auth/check-email` -- body `{"value": "..."}` → `{"available": true|false}`
- `POST /api/v1/auth/check-display-name` -- body `{"value": "..."}` → `{"available": true|false}`

Display name comparison is case-insensitive.

## Account Linking

Users who register with email can later link Steam, Discord, or Apple from profile settings. Social-auth users retain their recovery email from onboarding and may add password login later. Linking is explicit and user-initiated.

### Backend Endpoints

- `POST /api/v1/users/me/link-steam` -- validates Steam OpenID params, fetches the Steam profile, checks for conflicts, stores the Steam auth identity, and seeds the canonical avatar if it is still empty
- `POST /api/v1/users/me/link-discord` -- exchanges the Discord authorization code via PKCE, checks for conflicts, stores the Discord auth identity
- `POST /api/v1/users/me/link-apple` -- validates Apple identity token, checks for conflicts, stores the Apple auth identity
- `DELETE /api/v1/users/me/link-steam` -- clears the linked Steam auth identity
- `DELETE /api/v1/users/me/link-discord` -- clears the linked Discord auth identity
- `DELETE /api/v1/users/me/link-apple` -- clears the linked Apple auth identity
- `POST /api/v1/users/me/set-email-password` -- adds email/password login for social-only users

### Conflict Detection

If another user already owns the requested auth-capable provider identity (`steam`, `discord`, or `apple`), the link request returns `409`.

### Add Email/Password

- `POST /api/v1/users/me/set-email-password` accepts `{"email": "...", "password": "..."}`.
- Flutter should source that `email` from the already-saved canonical account email rather than treating this dialog as a second general email-edit surface.
- It sets `email` and `password_hash` on the current user.
- It returns `409` if the account already has email/password login or if the email belongs to another user.
- Flutter uses `has_password_login` instead of inferring auth state from `email`.

### Lockout Guard

Unlinking an auth provider is rejected with `422` if it would remove the user's last available login method. The backend counts these auth methods:

- `email + password`
- linked Steam identity
- linked Discord identity
- linked Apple identity

At least one must remain after unlink.

### Revoked Provider Lifecycle

Unlinking Steam, Discord, or Apple also stores a durable revoked-provider record keyed by `{provider, external_id}`. Future direct login with that same provider identity is blocked until the user signs in with another method and relinks it from profile settings. The current authenticated session remains valid after unlink.

## Flutter Auth Integration

The shared `OAuthLauncher` utility (`lib/features/auth/data/oauth_launcher.dart`) provides the auth and linking flows:

- `launchSteamAuth()` -- builds Steam OpenID URL, launches the browser, returns callback params
- `launchDiscordAuth()` -- builds a Discord PKCE auth URL, launches the browser, returns the authorization code plus PKCE verifier metadata
- `launchAppleSignIn()` -- launches Apple Sign-In, returns an identity token; on web it uses `WebAuthenticationOptions`
- login-side Steam and Discord auth both route through dedicated focused-flow screens that show the same cancellable progress UI before completing the provider callback handoff, while preserving any `from` redirect target back into the app
- Discord availability in Flutter/web is shared between auth surfaces and profile linking: the UI exposes Discord only when `DISCORD_CLIENT_ID` is baked into that Flutter build
- Apple availability in Flutter is shared between auth surfaces and profile linking: iOS may launch the native flow, while web only exposes Apple when `APPLE_SERVICE_ID` is configured for that build
- A missing Apple web service ID is treated as an unavailable local auth surface, not as a generic backend auth failure
- Login/register provider buttons use a shared provider-visual registry so each auth provider renders with its branded `line_icons` glyph and provider-authentic surface treatment, including Apple's maintained monochrome/light button style rather than a saturated platform fill

Connected-account rows on the profile screen trigger these flows directly, then refresh both the profile and auth providers after success.

Discord requires a registered application client id and redirect URIs, but uses the Discord public-client PKCE flow so the mobile/web app does not ship a confidential client secret in Flutter.

## Platform Callback Configuration

| Platform | Steam callback | Discord callback | Apple Sign-In | Config file(s) |
|----------|---------------|------------------|---------------|----------------|
| **iOS** | hosted `https://app.in-game.app/auth/steam-callback.html` page that bridges back to `ingame://auth/steam/callback` for the native auth session | `ingame://auth/discord/callback` custom-scheme callback via PKCE | Native AuthenticationServices via the app URL scheme | `ios/Runner/Info.plist`, `web/auth/steam-callback.html` |
| **Android** | hosted `https://app.in-game.app/auth/steam-callback.html` page that bridges back to `ingame://auth/steam/callback` for the native auth session | `ingame://auth/discord/callback` via Android intent filter | N/A (Apple Sign-In not on Android) | `android/app/src/main/AndroidManifest.xml`, `web/auth/steam-callback.html` |
| **Web** | `{origin}/auth/steam-callback.html` callback page resolves the browser flow | `{origin}/auth/discord-callback.html` callback page resolves the PKCE browser flow | `{origin}/auth/apple-callback.html` + `WebAuthenticationOptions(clientId, redirectUri)` | `web/auth/steam-callback.html`, `web/auth/discord-callback.html`, `web/auth/apple-callback.html` |

Additional constraints:

- The maintained SP1 auth callback contract covers the active product platforms only: iOS, Android, and Web.
- `flutter_web_auth_2` receives the valid custom scheme `ingame` for native Steam auth. The hosted Steam callback page adds an `ingame_native=1` bridge marker for native flows and redirects those sessions back into `ingame://auth/steam/callback`, while web still uses the callback HTML page messaging contract.
- Flutter runtime host defaults stay repo-local for development: `INGAME_API_BASE_URL=http://localhost:8000/api/v1`, `INGAME_WEB_APP_BASE_URL=http://localhost:8080`, and `INGAME_INVITE_BASE_URL=http://localhost:8080`.
- Native Steam callback generation uses `INGAME_WEB_APP_BASE_URL`, while invite/deep-link surfaces use `INGAME_INVITE_BASE_URL`.
- iOS associated domains remain required for invite links on `in-game.app`, but Steam auth no longer depends on a Universal Link association for `app.in-game.app`.
- Discord OAuth must use PKCE and the Discord app's public-client mode so native/web flows can exchange authorization codes without shipping a confidential client secret in Flutter.
- Discord auth requires two explicit config surfaces: backend/runtime must receive `INGAME_DISCORD_CLIENT_ID`, while Flutter/web builds must receive `DISCORD_CLIENT_ID` as a build-time `--dart-define` / Docker build arg so the browser bundle can expose the Discord button and construct the OAuth URL.
- If Discord auth is attempted while `INGAME_DISCORD_CLIENT_ID` is missing on the backend, the API returns `503 auth.discord_unavailable` instead of a generic OAuth-verification failure so operators can diagnose the missing runtime config directly.
- Production native builds must pass explicit host `--dart-define` values rather than relying on repo defaults; the maintained iOS release path uses a dedicated `scripts/release/ios_prod.sh` wrapper, defaulting to `flutter run` and switching to `flutter build ipa` only when `--build` is provided.
- The maintained iOS production wrapper also forwards `DISCORD_CLIENT_ID` when present so device runs and IPA builds stay aligned with the same Discord-enabled Flutter auth surface used by local and CI-driven builds.
- The maintained local Chrome helper `scripts/release/chrome_local.sh` consumes the current shell environment, re-execs under bash when launched through `sh`, defaults the browser app host to `http://localhost:8090` so it does not collide with the containerized `ingame-web` runtime on `8080` or the local marketing runtime on `8081`, supports overriding that port through `INGAME_WEB_DEV_PORT`, and forwards the local host defines plus `DISCORD_CLIENT_ID` and `APPLE_SERVICE_ID` into `flutter run -d chrome` so browser auth surfaces match the intended local web-login contract.
- The maintained web image build path must bake `DISCORD_CLIENT_ID` into `Dockerfile.web` build args in CI or local image builds; release/runtime environment variables alone cannot enable Discord in an already-built Flutter web bundle.
- Apple web Sign-In uses `--dart-define=APPLE_SERVICE_ID=com.kounex.ingame.web` in the maintained CI/web-image build path.
- The release web image build must bake the Apple service ID at build time (for example through `Dockerfile.web` build args in GitHub Actions); this is not a runtime container env because Flutter web reads it through `String.fromEnvironment`.
- The web entrypoint must also load Apple's browser SDK script (`appleid.auth.js`) in `web/index.html`; without that script the Flutter web Apple button can fail immediately before any network auth request begins.
- Backend Apple token verification must accept the configured list of Apple audiences (`INGAME_APPLE_CLIENT_IDS` or legacy `INGAME_APPLE_CLIENT_ID`) so native bundle IDs and the web service ID stay aligned with the shipped clients.
- The maintained backend defaults and release deployment wiring must use the chosen web Service ID `com.kounex.ingame.web`, not the earlier placeholder `com.ingame.web`.
- Release Helm/API deployments must inject `INGAME_APPLE_CLIENT_IDS` alongside the backend secret/config set; relying on an outdated fallback default is not sufficient once the maintained web Service ID changes.
- Unsupported native platforms must not expose actionable Apple login or link affordances. Connected-account UI may still show an already-linked Apple identity so users can manage it.

## Auth Failure Contract

Key auth business-rule failures must continue to return stable machine-readable codes, including:

- `auth.invalid_credentials`
- `auth.refresh_token_invalid`
- `auth.refresh_token_revoked`
- `auth.steam_openid_invalid`
- `auth.steam_profile_unavailable`
- `auth.discord_unavailable`
- `auth.discord_oauth_invalid`
- `auth.discord_profile_unavailable`
- `auth.apple_token_invalid`
- `auth.steam_relink_required`
- `auth.discord_relink_required`
- `auth.apple_relink_required`
- `user.email_password_already_set`
- `user.last_auth_method_required`

Flutter maps these codes to locale-aware user-facing messages instead of parsing English response text.

## Change Log

| Date | Section | What changed | Why |
|------|---------|--------------|-----|
| 2026-06-07 | Flutter auth integration | Added the dedicated focused Discord auth route/screen so login-side Discord uses the same cancellable progress handoff as Steam while preserving the post-login redirect target | Keeps the Discord browser handoff aligned with the established Steam auth UX instead of dropping users into an uninterruptible direct launch from the login form |
| 2026-06-07 | Steam avatar seeding and link profile fetch | Documented that Steam auth/link now fetches the Steam profile during linking too, seeds the canonical profile avatar only when `user.avatar_url` is empty, and keeps later Steam logins from overwriting an existing app avatar | Keeps the Steam provider contract aligned with the same one-time avatar bootstrap behavior now used for Discord while making link-time profile metadata dependable |
| 2026-06-07 | Discord avatar seeding | Documented that Discord auth seeds the canonical profile avatar only when `user.avatar_url` is still empty and never overwrites an existing app avatar later | Keeps the auth/login contract aligned with the intended one-time provider-avatar bootstrap behavior shown in profile UI |
| 2026-06-07 | Discord backend config failure contract | Added the explicit `503 auth.discord_unavailable` response when Discord auth is attempted without `INGAME_DISCORD_CLIENT_ID` on the backend | Makes local and self-hosted Discord misconfiguration fail with an actionable backend error instead of a misleading generic OAuth verification failure |
| 2026-06-07 | Recovery email requirement and add email/password | Clarified that `user.email` stays the one canonical account email after onboarding, that Flutter exposes a dedicated profile email-change flow, and that add-email/password should reuse the saved email instead of acting as a second email editor | Keeps the auth contract consistent across email, Apple, Discord, and Steam account flows while reserving verification work for a later dedicated pass |
| 2026-06-07 | Flutter auth integration | Moved the maintained local Chrome helper's default browser-auth port to `http://localhost:8090` so it avoids both the containerized web runtime on `8080` and the local marketing runtime on `8081` | Keeps Discord's strict local redirect URI predictable without colliding with the current local stack's occupied ports |
| 2026-06-07 | Flutter auth integration | Simplified the maintained local Chrome helper so it uses the current shell environment and only keeps the `sh` to `bash` re-exec behavior | Keeps the written helper contract aligned with developer shells that already export local auth defines through `~/.zshrc` or similar startup files |
| 2026-06-07 | Flutter auth integration | Documented the maintained local Chrome helper that sources `~/.localrc` and forwards Discord/Apple web build defines into `flutter run -d chrome` | Keeps local browser auth runs aligned with the same web-login gating contract used by image builds and other maintained helpers |
| 2026-06-07 | Flutter auth integration | Clarified that the shared auth-button visual contract is provider-authentic rather than always a saturated platform-color fill, covering Apple's maintained monochrome treatment | Keeps the written auth-button contract aligned with the shipped Apple surface after the provider-visual audit follow-through |
| 2026-06-07 | Platform callback configuration | Corrected the maintained Android Steam callback row to the hosted bridge-page flow instead of the old direct `CallbackActivity` wording | Keeps the written native Steam callback contract aligned with the shipped launcher behavior and avoids misconfiguring Android auth surfaces |
| 2026-06-07 | Flutter auth integration | Narrowed maintained native Apple auth availability to iOS so unsupported native platforms such as macOS do not expose dead Apple affordances | Keeps the written auth contract aligned with the active platform scope and the corrected Apple availability gate in Flutter |
| 2026-06-07 | Flutter auth integration | Documented the maintained shared provider-visual treatment for auth buttons, including branded `line_icons` glyphs and provider-colored button surfaces | Keeps the written auth UI contract aligned with the new shared provider icon system used across login and register surfaces |
| 2026-06-07 | iOS production wrapper | Documented that the maintained iOS production wrapper now forwards `DISCORD_CLIENT_ID` in addition to the host defines | Keeps native release/device runs aligned with the same Discord-enabled Flutter build contract used elsewhere |
| 2026-06-07 | Provider config wiring | Documented the required Discord client-id wiring across backend runtime, Flutter build-time defines, and the maintained web-image path | Keeps the written auth/deployment contract aligned with the new Discord auth implementation so operators know exactly where to provide values |
| 2026-06-07 | Supported methods, auth flow, account linking, and callback config | Added Discord PKCE auth as a first-class sign-in and linking method, clarified that auth identities now live under the normalized social-identity contract, and extended the lockout/revocation rules to Discord | Aligns the auth spec with the new provider-capability model so login methods and social identities can grow without hardcoding more user columns |
| 2026-06-06 | Platform config | Documented that the Flutter web entrypoint must load Apple's `appleid.auth.js` browser SDK in addition to baking the Service ID define | Prevents the web Apple button from failing immediately in-browser before any auth network request starts |
| 2026-06-06 | Platform config | Corrected the maintained backend default/web Service ID alignment to `com.kounex.ingame.web` and documented that Helm API releases must inject `INGAME_APPLE_CLIENT_IDS` explicitly | Prevents Apple Sign-In regressions where web builds and backend audience validation drift apart despite the chosen production Service ID |
| 2026-06-06 | Platform config | Replaced the placeholder web Apple service ID with the maintained `com.kounex.ingame.web` identifier and documented that the web value must be baked into the CI-built Flutter web image instead of injected at container runtime | Keeps the written Apple web deployment contract aligned with the actual Flutter web build model and chosen Service ID |
| 2026-06-05 | Flutter auth integration and platform config | Added the shared Apple availability gate, documented the web-configured `APPLE_SERVICE_ID` requirement, and switched backend Apple verification to a configured audience list instead of a single client ID | Fixes the production web Apple mismatch and keeps login/link UI aligned with the actual supported runtime contract |
| 2026-06-04 | Spec topology | Created a dedicated auth spec by extracting auth and identity rules from the larger SP1 core-platform spec | Reduces spec size, merge conflicts, and update risk while keeping the auth contract focused |
| 2026-06-04 | Failure contract alignment | Corrected the refresh-token revoke code, documented the Steam first-login `503` fallback, and narrowed the maintained callback table to iOS/Android/Web | Keeps the written auth contract aligned with the implemented backend/client behavior and current platform scope |
| 2026-06-04 | Runtime host defaults | Clarified that Flutter runtime host defaults stay localhost for repo-independent development and that production native builds must pass explicit host defines | Prevents production domains from being hidden in the default repo config while keeping callback host behavior explicit |
| 2026-06-04 | iOS wrapper interface | Updated the maintained iOS production wrapper contract so `ios_prod.sh` defaults to `flutter run` and uses `--build` to produce an IPA | Keeps the documented production helper aligned with the implemented script behavior and interactive device testing workflow |
| 2026-06-04 | iOS Steam callback | Switched the maintained iOS Steam callback contract to the hosted `https://app.in-game.app/auth/steam-callback.html` Universal Link flow and documented the required associated-domain/AASA coverage | Prevents iOS production Steam sign-in from stalling on the callback page and being misread as a manual cancellation |
| 2026-06-04 | iOS Steam bridge fallback | Replaced the direct iOS HTTPS callback contract with a hosted-page bridge back into `ingame://auth/steam/callback` and removed the `app.in-game.app` auth-specific Universal Link dependency | Restores a more compatible native Steam auth flow after the direct iOS HTTPS callback path failed before presenting Steam on-device |
