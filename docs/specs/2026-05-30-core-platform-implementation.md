---
spec: core-platform-implementation
version: "1.11"
status: complete
last_updated: "2026-06-04"
sub_project: 1
---

# InGame -- Core Platform Implementation Spec

> Part of the [InGame Product Roadmap](roadmap.md) and the [Core Platform overview](2026-05-30-core-platform-design.md)

## Scope

This spec covers the implementation-facing SP1 app and shared-platform contracts:
- feature-first Flutter structure
- shared widget and service boundaries
- design-system rules
- navigation conventions
- localization and failure-handling patterns
- testing expectations

## Flutter Architecture

### Pattern: Feature-First

The Flutter app is organized by feature, with each feature owning:

- `data/`
- `domain/`
- `presentation/`

Shared foundations live under:

- `lib/core/` for lower-level app infrastructure
- `lib/shared/` for cross-feature widgets, helpers, and shared services

Representative layout:

```text
lib/
  core/
    localization/
    networking/
    routing/
    storage/
    theme/
    utils/
  features/
    auth/
    onboarding/
    profile/
    groups/
  shared/
    providers/
    services/
    widgets/
  l10n/
```

### Key Patterns

- Riverpod providers live in `presentation/providers/`
- repositories use handwritten Dio calls and map JSON into Freezed/domain models
- user-visible failures that survive rebuilds are modeled as typed `AppFailure` values
- locale changes revalidate already-visible form errors, while untouched forms stay quiet
- generated API artifacts, if reintroduced later, are treated as read-only

### API Contract Pipeline

1. Backend Pydantic schemas define the REST contract.
2. FastAPI emits OpenAPI.
3. Flutter repositories consume the contract through handwritten Dio calls.
4. Domain models match the backend schema shapes.
5. CI validates backend/frontend contract alignment.

## Shared App Boundaries

### Shared Primitives

- `UserAvatar` -- low-level avatar rendering and initials fallback
- `EditableAvatarField` -- shared avatar editing surface for onboarding and profile edit
- `WeeklyAvailabilityEditor` -- shared recurring-availability editor
- `LanguageSwitcher` -- shared locale-switching surface
- `AppToast` -- shared feedback/toast system

### Shared Services

- `AvatarUploadService` -- upload-init request plus direct object-storage avatar upload helper

### Runtime Storage Integration

- Avatar storage remains S3-compatible across environments.
- Local development uses bundled MinIO plus automatic avatar-bucket bootstrap
  and server-level CORS so browser upload flows work without manual
  object-storage setup.
- Runtime config may split the API's internal object-storage endpoint from the
  browser-facing upload base URL when uploads need to traverse a different
  public host than the backend uses internally.
- Flutter does not carry a separate MinIO or avatar-upload-host `--dart-define`;
  it talks to the API base URL and consumes backend-provided `upload_url` /
  `avatar_url` values from the maintained upload contract.
- `docker-compose.release.yml` now includes bundled MinIO by default for
  self-hosted environments while still allowing operators to repoint the API at
  a different S3-compatible backend if they intentionally customize the stack.
- The release compose bootstrap path is inlined inside the MinIO helper service
  so stack deployers like Portainer do not depend on repo-file bind mounts for
  bucket initialization, and it overrides the `minio/mc` entrypoint with
  `/bin/sh -ec` so Podman/Portainer execute the inline shell bootstrap instead
  of treating it as an `mc` subcommand.
- Helm/OpenShift deployments continue treating avatar storage as external
  runtime configuration rather than a chart-managed dependency.

## Design System: Glassmorphism

### Color Palette

- Background: deep dark gradient
- Glass surfaces: low-opacity frosted layers with blur
- Primary accent: electric blue
- Secondary accent: purple
- Success accent: vivid green
- Text: white primary, muted secondary and tertiary tiers

### Core Components

- `GlassCard`
- `GlassAppBar`
- `GlassBottomNav`
- `GlassButton`
- `GlassInput`
- `StatusIndicator`
- `AvatarWithStatus`
- `InGameLogo`
- `SocialLoginButtons`
- `AppToast`
- `AdaptiveShell`

### Interaction Conventions

- desktop/web tappables use a pointer cursor
- desktop/web pages use shared width archetypes so single-column content stays readable on ultrawide screens while the shell/sidebar remains fixed; the maintained presets are `compact` (~560), `form` (~720), `reading` (~960), `wide` (~1120), and opt-in `full`
- width constraints apply to the page canvas, not every nested card or button; screens should assign one preset by archetype instead of inventing ad-hoc per-screen max widths
- focused flows outside the shell center their constrained content in the viewport, while shell-contained pages center their constrained content inside the right-hand content pane without moving the left navigation rail
- shared app bars may align to the same width preset as the page body on desktop/web so toolbar content and constrained page content stay visually connected
- shell-route dialogs and bottom sheets use the root navigator so overlays render above persistent navigation
- new user-facing strings must be localized through ARB files
- popup menus follow the global glass theme
- async field-availability feedback uses compact suffix status affordances where both loading and error glyphs share the same aligned wrapper, and surfaces localized inline error text through the input instead of relying on icon-only failure states

### Motion Rules

- web may keep richer custom route transitions where appropriate
- iOS/Android should preserve native navigation feel
- Cue is used where it has clear value: card entry, toasts, social hover states, onboarding feedback, and status pulses

## Navigation Structure

### Hybrid Persistent Navigation

The app uses persistent navigation for browsable content and hides it for focused flows.

Inside the shell:
- Home / Groups
- Discover
- Profile
- nested routes such as create-group, group-detail, settings, and edit-profile stay within the shell

Outside the shell:
- login
- register
- Steam auth callback flow
- invite/join flow
- onboarding

### Redirect Rules

- protected routes can preserve a `from` target
- onboarding can interrupt a protected/deep-link flow, then return to it afterward
- explicit logout goes to a clean login route without preserving stale return targets

## Localization Contract

- English and German ARB catalogs are the source of truth for user-facing Flutter copy
- widgets use `context.l10n`
- non-widget helpers use the locale-aware fallback accessor
- shared widget copy, validator copy, dialogs, helper text, and error/toast messages are all included in the localization contract

## Testing Expectations

- widget tests cover screens, forms, and localized UI behavior
- provider/repository tests cover state and network mapping behavior
- shared widgets with meaningful branching behavior should get focused widget tests when practical

## Change Log

| Date | Section | What changed | Why |
|------|---------|--------------|-----|
| 2026-06-04 | Interaction conventions | Added the maintained desktop/web page-width archetype contract (`compact`, `form`, `reading`, `wide`, opt-in `full`) plus alignment rules for focused flows, shell content, and matching app bars | Prevents ultrawide web layouts from stretching single-column flows while keeping width decisions consistent and reusable |
| 2026-06-04 | Interaction conventions | Refined compact async-validation affordances so both the trailing spinner and trailing error glyph use the same aligned compact wrapper instead of mismatched slot treatment, while still showing localized inline error text | Keeps the shared input contract aligned with the maintained register/onboarding validation UX |
| 2026-06-04 | Spec topology | Reframed the former UI-architecture child spec as the SP1 implementation spec while preserving its content focus on Flutter structure, shared app contracts, design-system rules, navigation, localization, and testing expectations | Aligns SP1 naming with the SP2 overview plus implementation pattern without a broad content rewrite |
| 2026-06-04 | Runtime storage integration | Documented the bundled MinIO local-dev path, the default bundled MinIO release-compose path for self-hosted installs, the split between internal storage endpoints and browser-facing upload hosts when needed, and that Flutter consumes backend-provided upload URLs rather than a separate MinIO define | Captures the supported self-hosted avatar-storage topology without changing the Flutter/backend upload contract |
| 2026-06-04 | Portainer-safe release bootstrap | Clarified that the release MinIO bootstrap is inlined in compose rather than mounted from repo files, and that it overrides the `minio/mc` entrypoint with `/bin/sh -ec` for Podman/Portainer compatibility | Keeps the self-hosted release path compatible with stack deployers that do not project repo-relative helper files into containers |
