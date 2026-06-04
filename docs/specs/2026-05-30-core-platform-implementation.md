---
spec: core-platform-implementation
version: "1.1"
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
- `docker-compose.release.yml` keeps storage external by default but may opt
  into a bundled MinIO profile for small self-hosted environments.
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
- shell-route dialogs and bottom sheets use the root navigator so overlays render above persistent navigation
- new user-facing strings must be localized through ARB files
- popup menus follow the global glass theme

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
| 2026-06-04 | Spec topology | Reframed the former UI-architecture child spec as the SP1 implementation spec while preserving its content focus on Flutter structure, shared app contracts, design-system rules, navigation, localization, and testing expectations | Aligns SP1 naming with the SP2 overview plus implementation pattern without a broad content rewrite |
| 2026-06-04 | Runtime storage integration | Documented the bundled MinIO local-dev path, the optional release-compose MinIO profile, and the split between internal storage endpoints and browser-facing upload hosts when needed | Captures the supported self-hosted avatar-storage topology without changing the Flutter/backend upload contract |
