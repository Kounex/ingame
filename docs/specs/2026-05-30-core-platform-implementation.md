---
spec: core-platform-implementation
version: "1.36"
status: complete
last_updated: "2026-06-05"
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
- `InGameLogo` -- shared brand wordmark that pairs the canonical logo image asset with the gradient `InGame` text treatment
- `AppToast` -- shared feedback/toast system
- `SharedAnimatedBackground` -- one shared premium ambient background layer rendered behind routes
- `AppBackgroundSurface` -- shared translucent page scrim that keeps route content readable over the animated background while still letting ambient color and motion register
- `DebugOverlayCard` -- shared debug-only glass overlay shell for session-scoped developer tools and diagnostics

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
- focused flows that render over the shared ambient background may use a dedicated transition distinct from generic shell/detail pushes; the current maintained contract is a focused-flow custom transition where the covered auth/onboarding/join route drops to near-zero opacity very early, while the incoming route begins fading in shortly after the handoff starts so shell/dashboard content becomes readable quickly, with the shared root `AppBackgroundSurface` above the navigator keeping the ambient background and scrim stable beneath navigation
- logged-in web route transitions for shell/detail navigation should use a staggered fade-slide handoff where the covered route gets a visible head start moving/fading left, then overlaps with the incoming route for the back half of the transition so push/pop read like the same motion in reverse
- shell branch root screens that need to animate as the covered route during logged-in web navigation must be declared with explicit `pageBuilder` pages rather than plain `builder` widgets, otherwise the outgoing shell screen cannot participate in the maintained handoff
- the root router should disable automatic route focus requests on push so initial web view focus changes do not ask Flutter focus traversal to inspect navigator theater layout before the route tree has settled
- shared app bars may align to the same width preset as the page body on desktop/web so toolbar content and constrained page content stay visually connected
- shell-route dialogs and bottom sheets use the root navigator so overlays render above persistent navigation
- route-level backgrounds should prefer the shared `AppBackgroundSurface` scrim over bespoke opaque full-screen gradients so the ambient app background can remain visible behind content
- the app root may host a single shared `AppBackgroundSurface` above the navigator so focused-flow route transitions reuse one stable scrim instead of animating separate per-screen background layers; nested route-level `AppBackgroundSurface` usage should collapse to a no-op when that shared root surface is already present
- new user-facing strings must be localized through ARB files
- popup menus follow the global glass theme
- app-wide `Divider` and `PopupMenuDivider` usage should resolve to an ultra-subtle cool-gray hairline separator so list rows, section splits, and menu groupings stay barely visible in the liquid-glass visual language
- async field-availability feedback uses compact suffix status affordances where both loading and error glyphs share the same aligned wrapper, and surfaces localized inline error text through the input instead of relying on icon-only failure states

### Motion Rules

- web may keep richer custom route transitions where appropriate
- iOS/Android should preserve native navigation feel
- Cue is used where it has clear value: card entry, toasts, social hover states, onboarding feedback, and status pulses
- continuous shader motion should stay centralized in one shared ambient background layer and remain subtle, low-contrast, and premium rather than visually loud
- web should prefer a robust animated orb fallback when runtime shader output is inconsistent or too faint in browser renderers; the fallback still needs clearly visible hue drift and spatial motion rather than reading as a brightness-only wash
- browser ambient motion should use a legible cadence and travel distance so movement remains perceptible behind translucent surfaces instead of requiring users to stare for several seconds to notice drift
- shared ambient loops must be seamless; browser fallback paths should use periodic motion curves that return to the same trajectory at cycle boundaries instead of snapping back to a new starting position
- shader-driven accents may be added to a small number of hero or navigation surfaces, but dense lists, per-member presence rows, and blur-heavy repeated cards should stay on event-driven motion only
- animated background systems must provide a graceful fallback and respect reduced-motion expectations
- debug builds may expose session-only motion controls, including global `timeDilation`, through a visible collapsible overlay instead of hidden startup overrides so transition capture and shader tuning stay inspectable during development; the maintained default slowdown is `1x`

### Brand Asset Contract

- `assets/images/ingame-logo.png` is the canonical brand asset source for app icons, native splash imagery, and shared brand-mark usage in Flutter UI
- native Android/iOS launch icons are generated from that asset via `flutter_launcher_icons`
- native Android/iOS splash imagery is generated from that asset via `flutter_native_splash`
- Flutter web favicon and manifest icons should resolve to derived outputs generated from the same source asset
- standalone gameplay icons may remain generic where they communicate a feature meaning rather than product identity

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
| 2026-06-05 | Brand asset contract | Documented `assets/images/ingame-logo.png` as the canonical generated icon/splash source and clarified that `InGameLogo` now uses the real logo image beside the gradient wordmark | Keeps the shared Flutter branding contract aligned with the shipped asset-driven rollout |
| 2026-06-05 | Interaction conventions | Added the maintained ultra-subtle cool-gray hairline divider treatment for app-wide `Divider` and `PopupMenuDivider` usage | Aligns separators with the liquid-glass visual target so they organize content without reading as bright borders |
| 2026-06-05 | Shared background and motion rules | Added the shared animated ambient background layer, the translucent page-surface scrim contract, and guardrails for keeping shader motion subtle and centralized | Increases visual fidelity without scattering continuous heavy rendering across every screen or glass component |
| 2026-06-05 | Shared background and motion rules | Clarified that web may use a stronger animated orb fallback and that the page scrim must still leave visible color/motion behind content | Fixes the browser case where the ambient system read as a brightness-only overlay instead of visible ambient motion |
| 2026-06-05 | Shared background and motion rules | Tightened the browser ambient fallback cadence/travel expectation so shared background motion stays visibly alive instead of reading as static glow | Captures the follow-up fix for web where color became visible but movement still felt imperceptible |
| 2026-06-05 | Shared background and motion rules | Added the seamless-loop requirement for ambient fallback motion so cycle resets do not produce visible jumps in browser rendering | Captures the follow-up fix for web where motion became noticeable but the loop seam still snapped at the end of each cycle |
| 2026-06-05 | Interaction conventions | Clarified that focused full-screen flows over the shared ambient background should avoid web cross-fade/slide route transitions when transparent surfaces would ghost the outgoing screen beneath the incoming one | Fixes the auth-flow routing artifact introduced once focused flows adopted the shared translucent background treatment |
| 2026-06-05 | Interaction conventions | Refined focused-flow web transitions to allow slide/fade motion again when a stable full-screen backdrop is staged above the outgoing route during the transition | Keeps the auth/onboarding flows feeling polished without reintroducing the ghosted previous-screen artifact |
| 2026-06-05 | Interaction conventions | Added the shared root-surface contract above the navigator and documented that nested per-screen background scrims collapse when that root surface exists | Aligns the transition fix with the maintained architecture so the ambient background and scrim remain stable across route animations instead of moving page-by-page |
| 2026-06-05 | Interaction conventions | Reverted focused-flow routes back to the original standard web fade/slide transition now that the shared root surface keeps the ambient background and scrim stable across navigation | Restores the original motion feel after the root-surface fix removed the earlier need for a helper-owned transition backdrop |
| 2026-06-05 | Interaction conventions | Switched the focused auth/onboarding/join flow experiment to a dedicated custom transition where the incoming route fades in while the covered route fades out and moves left | Matches the desired navigation feel more directly than the prior Cupertino-page experiment while preserving the shared root-surface stability beneath route changes |
| 2026-06-05 | Interaction conventions | Disabled automatic router focus requests on push so initial web view focus changes no longer race navigator theater layout during startup redirects into focused flows | Fixes the startup `_RenderTheater ... was not laid out` assertion path triggered from `didChangeViewFocus` rather than from user-driven route transitions |
| 2026-06-05 | Interaction conventions | Refined the focused-flow custom transition into a staggered handoff so the covered route begins fading/moving out before the incoming route starts fading in late via an interval | Matches the desired auth-flow motion more closely by avoiding a direct crossfade between two nearly identical centered-card screens |
| 2026-06-05 | Shared primitives and motion rules | Added the shared `DebugOverlayCard` contract and documented that debug-only motion tools like global `timeDilation` should live in a collapsible session-scoped overlay rather than in hidden startup defaults | Keeps developer-facing motion/shader controls inspectable, discoverable, and temporary without affecting release behavior |
| 2026-06-05 | Interaction conventions | Tightened the focused-flow handoff so the covered auth route fades to near-zero opacity quickly and the incoming shell/dashboard route starts becoming visible much earlier in the transition | Fixes the login-to-dashboard web case where the previous focused-flow screen stayed fully readable under the incoming shell and made the handoff feel clipped |
| 2026-06-05 | Interaction conventions | Added the maintained staggered delayed-entry contract for logged-in web route transitions so covered shell/detail routes animate first and incoming content fades in after a short delay | Keeps authenticated in-app navigation polished without applying the same timing profile as the focused auth/onboarding handoff |
| 2026-06-05 | Interaction conventions | Lengthened the logged-in web push handoff so the covered page stays visibly sliding/fading out for much more of the transition instead of dropping away too quickly | Brings forward in-shell pushes closer to the perceived timing of the reverse handoff where the outgoing page motion already felt correct |
| 2026-06-05 | Interaction conventions | Clarified that shell branch root routes must use explicit page builders so covered in-shell pages receive outgoing transition animations during logged-in web navigation | Captures the configuration fix behind the remaining overlap case where root shell pages stayed static and then disappeared instead of animating out |
| 2026-06-05 | Interaction conventions and motion rules | Aligned the logged-in web transition contract with the final head-start-then-overlap timing model and reset the maintained debug overlay `timeDilation` default to `1x` | Keeps the written contract aligned with the user-approved route feel while restoring normal-speed app behavior as the default debug starting point |
