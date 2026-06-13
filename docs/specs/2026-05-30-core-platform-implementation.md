---
spec: core-platform-implementation
version: "1.67"
status: complete
last_updated: "2026-06-10"
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
- user-scoped Riverpod caches must watch the shared session-reset signal so logout or forced auth invalidation clears stale in-memory data before another account signs in
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
- `AppAnchoredPopoverMenuItem` -- shared selected-row treatment for anchored selector menus
- `AppDropdownSelector` -- shared wrapper for input-like dropdown fields that should keep the stock `DropdownButtonFormField` interaction model while matching the app's maintained menu styling
- `AppPopupMenuButton` -- shared wrapper for ellipsis/action popup menus that keeps the global glass shell while suppressing default gray hover, highlight, and splash states inside action rows
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
- The API records each issued avatar upload in a database-backed ledger keyed by
  user, object key, and public `avatar_url` so unclaimed direct uploads can be
  cleaned without bucket-wide scans.
- Successful `PATCH /api/v1/users/me` avatar persistence marks the matching
  ledger row committed in the same database transaction as the profile update so
  the janitor never treats the active canonical avatar as disposable.
- The API runtime owns an in-process janitor loop that periodically deletes
  uncommitted avatar uploads older than
  `INGAME_AVATAR_UPLOAD_UNCLAIMED_TTL_HOURS` (default `24`) and removes their
  ledger rows; storage failures are logged and retried on later passes.
- Runtime config may split the API's internal object-storage endpoint from the
  browser-facing upload base URL when uploads need to traverse a different
  public host than the backend uses internally.
- Flutter does not carry a separate MinIO or avatar-upload-host `--dart-define`;
  it talks to the API base URL and consumes backend-provided `upload_url` /
  `avatar_url` values from the maintained upload contract.
- `docker-compose.release.yml` now includes bundled MinIO by default for
  self-hosted environments while still allowing operators to repoint the API at
  a different S3-compatible backend if they intentionally customize the stack.
- Containerized Flutter web builds must ignore host-generated artifacts such as
  `.dart_tool/`, `build/`, and platform ephemeral folders so Podman/Docker
  image builds regenerate package config inside the container instead of
  inheriting workstation-specific absolute paths from the repo checkout.
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
- `AppAnchoredPopoverSelector`
- `AppAnchoredPopoverMenuItem`
- `AppListRow`
- `AppSwitchRow`
- `AppChip`
- `AppDropdownSelector`
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
- iOS route pages should use a Cupertino-preserving custom page/route layer that keeps the interactive back swipe while adding an aggressive fade on top of the stock Cupertino transition so transparent app surfaces do not leave the covered route fully readable mid-handoff
- shell branch root screens that need to animate as the covered route during logged-in web navigation must be declared with explicit `pageBuilder` pages rather than plain `builder` widgets, otherwise the outgoing shell screen cannot participate in the maintained handoff
- shell branch switches remain indexed-stack swaps, so their handoff is intentionally immediate; the maintained custom page transitions apply to focused flows and pushed route pages rather than tab-branch changes
- the root router should disable automatic route focus requests on push so initial web view focus changes do not ask Flutter focus traversal to inspect navigator theater layout before the route tree has settled
- shared app bars may align to the same width preset as the page body on desktop/web so toolbar content and constrained page content stay visually connected
- shell-route dialogs and bottom sheets use the root navigator so overlays render above persistent navigation
- shared confirmation dialogs should be reserved for destructive, role-changing, session-ending, or socially meaningful actions that are easy to trigger accidentally; routine save/join/RSVP/edit actions stay single-step and use their existing button or form surface as the commitment point
- repeated UI should be extracted by boundary, not by visual coincidence alone: design-system primitives belong in shared/core widget layers, repeated slot-based layouts belong in shared composites, and richer semantic controls such as readiness or RSVP stay domain-local unless a second true consumer emerges with matching behavior
- live-detail overlays must react to authoritative state changes; if a session or other live-backed entity disappears while its sheet is open, the overlay should dismiss or move into an explicitly non-interactive removed state instead of preserving stale mutation controls
- route-level backgrounds should prefer the shared `AppBackgroundSurface` scrim over bespoke opaque full-screen gradients so the ambient app background can remain visible behind content
- the app root may host a single shared `AppBackgroundSurface` above the navigator so focused-flow route transitions reuse one stable scrim instead of animating separate per-screen background layers; nested route-level `AppBackgroundSurface` usage should collapse to a no-op when that shared root surface is already present
- new user-facing strings must be localized through ARB files
- popup menus follow the global glass theme
- ellipsis/action popup menus should route through `AppPopupMenuButton` so popup rows inherit transparent hover, highlight, and splash states instead of the stock Material gray interaction overlay
- selector-style popovers should use the shared `AppAnchoredPopoverSelector` rather than ad-hoc `PopupMenuButton` implementations so compact and settings-row triggers still share one maintained popup behavior path
- anchored selector popovers should cap their initial menu height to roughly one-third of the current viewport, keep scrolling inside the popover surface, show a scrollbar only when scrolling is needed, and prefer opening below or above the trigger based on available space before falling back to screen-edge clamping
- anchored selector triggers must remain keyboard-focusable and support standard activation keys (`Enter` / `Space`) so shared popover controls stay accessible on web and desktop
- input-like dropdown fields that open the stock `DropdownButtonFormField` route should explicitly use the same opaque dark surface and rounded menu radius family as popup selectors, keep the menu width aligned to the field instead of the stock inflated route width, suppress the stock gray hover/press/splash treatment, and render the currently selected option with the same blue-tinted highlighted row treatment and checkmark affordance inside the open list
- weekly availability preset chips should use their semantic leading icon as the sole leading affordance even when selected, and should emit the shared subtle selection haptic on each toggle
- app-wide `Divider` and `PopupMenuDivider` usage should resolve to an ultra-subtle cool-gray hairline separator so list rows, section splits, and menu groupings stay barely visible in the liquid-glass visual language
- async field-availability feedback uses compact suffix status affordances where both loading and error glyphs share the same aligned wrapper, and surfaces localized inline error text through the input instead of relying on icon-only failure states
- mobile tactile feedback should stay subtle and semantic through one shared helper: use light selection feedback for discrete toggles or choice changes, light success feedback for successful commits and refresh completion, and a slightly firmer pulse only after confirmed destructive or session-ending actions; web and desktop remain no-op
- dropdown-style controls may use the same subtle selection haptic both when the menu opens and when an item is chosen, including popup selectors, popup action menus, and form dropdown fields

### Motion Rules

- web may keep richer custom route transitions where appropriate
- iOS/Android should preserve native navigation feel, even when iOS overlays a stronger fade on top of the Cupertino route to keep transparent surfaces from ghosting previous content
- Cue is used where it has clear value: card entry, toasts, social hover states, onboarding feedback, and status pulses
- continuous shader motion should stay centralized in one shared ambient background layer and remain subtle, low-contrast, and premium rather than visually loud
- web should prefer a robust animated orb fallback when runtime shader output is inconsistent or too faint in browser renderers; the fallback still needs clearly visible hue drift and spatial motion rather than reading as a brightness-only wash
- browser ambient motion should use a legible cadence and travel distance so movement remains perceptible behind translucent surfaces instead of requiring users to stare for several seconds to notice drift
- shared ambient loops must be seamless; both shader and browser fallback paths should use periodic motion inputs that return to the same visual state at cycle boundaries instead of snapping back to a new starting position
- shader-driven accents may be added to a small number of hero or navigation surfaces, but dense lists, per-member presence rows, and blur-heavy repeated cards should stay on event-driven motion only
- animated background systems must provide a graceful fallback and respect reduced-motion expectations
- release builds must install the shared ambient motion scope too, with a renderer-aware production baseline: native fragment-shader paths default to ambient intensity `0.0`, while web and any fallback renderer default to `0.8` so browser/fallback backgrounds still read clearly on phone-sized screens without overdriving the native shader path
- mobile-native shader rendering may apply an additional visibility boost plus tighter blob radius/softness, stronger chroma, and low-frequency shape distortion on top of the shared ambient intensity so iPhone/Android devices keep clearly readable cyan/purple accent spots with more organic silhouettes without changing the maintained web fallback look
- debug/runtime diagnostics for the ambient background should report the actual current renderer mode (`loading`, `shader`, `fallback`) rather than assuming every non-web build is using the shader
- debug builds may expose session-only motion controls, including global `timeDilation`, through a visible collapsible overlay instead of hidden startup overrides so transition capture and shader tuning stay inspectable during development; the maintained default slowdown is `1x`, and the outer debug card should start collapsed until the developer explicitly expands it
- debug builds may also expose a session-only ambient shader diagnostic mode plus a scrim bypass toggle so mobile-device investigations can temporarily force unmistakable neon blobs on a near-unmasked surface without changing release visuals
- focused transparent flows such as login/register/onboarding should minimize overlapping translucent glass surfaces during navigation; the covered route may fade out quickly while the incoming route waits briefly before revealing with a delayed fade/slide handoff so auth-style transitions avoid the temporary dark-film/brightness-kick artifact at completion

### Brand Asset Contract

- `assets/images/ingame-logo.png` is the canonical brand asset source for app icons, native splash imagery, and shared brand-mark usage in Flutter UI
- `InGameLogo` should render that canonical logo asset as-is in Flutter UI without additional runtime corner clipping so the source artwork's own rounded shape and padding remain intact
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
- nested routes such as create-group, group-detail, and settings stay within the shell
- the profile tab itself is the maintained post-onboarding settings hub; routine
  profile edits should prefer in-place sheets/dialogs/selectors over a separate
  dedicated `edit-profile` route

Outside the shell:
- login
- register
- Steam auth callback flow
- Discord auth callback flow
- invite/join flow
- onboarding

### Redirect Rules

- protected routes can preserve a `from` target
- focused auth callback routes such as Steam and Discord preserve `from` and return to login cleanly on user cancellation
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
| 2026-06-10 | Runtime storage integration | Added the avatar upload ledger plus the in-process 24-hour unclaimed-upload janitor and documented the new TTL runtime setting | Keeps the implementation-facing storage/runtime contract aligned with the new backend cleanup path instead of relying on implicit bucket state |
| 2026-06-08 | Navigation structure | Retired the dedicated `edit-profile` route from the maintained shell-navigation contract and clarified that post-onboarding profile edits should prefer in-place settings surfaces on the profile tab | Keeps the implementation-facing routing contract aligned with the approved profile UX simplification instead of preserving a redundant full-screen edit destination |
| 2026-06-08 | Key patterns | Added the shared session-reset requirement for user-scoped Riverpod providers and realtime clients on logout or forced auth invalidation | Keeps the maintained Flutter state-lifecycle contract aligned with the logout hardening that prevents stale account data from surviving across sign-ins |
| 2026-06-07 | Navigation structure and redirect rules | Added the dedicated Discord auth callback flow beside Steam and documented that focused auth callback routes preserve `from` while still allowing a clean cancel path back to login | Keeps the routing contract aligned with the maintained cancellable provider-auth handoff UX instead of treating Discord as a special direct-launch exception |
| 2026-06-07 | Shared primitives and interaction conventions | Added `AppPopupMenuButton` as the maintained wrapper for ellipsis/action menus and documented the no-gray hover/highlight/splash contract for popup action rows | Keeps action menus visually aligned with the glass system instead of falling back to default Material ink states in different features |
| 2026-06-07 | Runtime storage integration and local image builds | Added the maintained requirement that containerized Flutter web builds ignore host-generated artifacts like `.dart_tool/` so Podman/Docker rebuilds regenerate package config inside the container | Keeps the deployment/build contract aligned with the local stack path needed to rebuild the current workspace successfully |
| 2026-06-06 | Interaction conventions | Clarified that weekly availability preset chips keep their semantic icon as the only leading affordance when selected and emit subtle selection haptics on toggle | Prevents selected preset chips from showing a conflicting overlapping checkmark over the existing icon and aligns the shared availability editor with the app-wide toggle haptics contract |
| 2026-06-06 | Interaction conventions | Tightened the selector-popover rule so selector-style popovers should always route through `AppAnchoredPopoverSelector`, regardless of list length, while keeping custom trigger chrome in feature wrappers | Removes the last split between stock popup buttons and the shared anchored popover so selector popovers have one maintained implementation path |
| 2026-06-06 | Core components and interaction conventions | Added `AppAnchoredPopoverSelector` as the maintained shared widget for long selector-style popovers, including scrollbar, internal scroll, and preferred above/below anchored opening before clamp fallback | Gives long lists like timezone a reusable anchored popover path that avoids the stock popup route's visible repositioning and hidden scrolling affordance |
| 2026-06-06 | Interaction conventions | Added the maintained popup-selector sizing rule that long popup lists should open with an internal height cap of about one-third of the viewport and scroll within that surface | Prevents long selector popovers like timezone from opening at full height and then visibly shifting position just to fit on screen |
| 2026-06-06 | Shared primitives, core components, and interaction conventions | Reverted the maintained language/timezone selector contract back to dedicated popup-style implementations instead of requiring them to share the stock `DropdownButtonFormField` wrapper path | Restores the previously approved compact/settings selector look while keeping the stock-field dropdown treatment available only where the input-like variation is actually desired |
| 2026-06-06 | Shared primitives, core components, and interaction conventions | Added `AppDropdownSelector` as the maintained shared wrapper for selector-style and input-like dropdowns, and documented that compact/settings triggers should route through it when they rely on `DropdownButtonFormField` under the hood | Keeps timezone, language, and coordination status dropdowns on one shared stock-menu implementation while preserving the non-input selector look for compact/settings surfaces |
| 2026-06-06 | Interaction conventions | Tightened the stock dropdown parity rule so input-like dropdown menus stay width-aligned to the field and suppress the default gray hover/press/splash treatment while keeping the selector-style selected row | Ensures stock `DropdownButtonFormField` menus feel like the same polished component family as timezone/language selectors instead of falling back to default Material route behavior |
| 2026-06-06 | Interaction conventions | Documented that anchored popover triggers must stay keyboard-focusable and that live-backed detail sheets should dismiss stale controls when their backing entity disappears | Closes the remaining accessibility and stale-state gaps surfaced in the final audit verification pass |
| 2026-06-06 | Interaction conventions | Refined the stock dropdown visual rule so input-like dropdown menus also match the selector-style selected-row treatment with blue tint and a checkmark inside the open list | Keeps the coordination status dropdown visually aligned with the timezone/language selector pattern instead of only matching the outer menu shell |
| 2026-06-06 | Interaction conventions | Added the maintained visual rule that stock input-like dropdown menus must explicitly use the same opaque popup surface family as shared selectors | Prevents `DropdownButtonFormField` menus from opening with a transparent hard-to-read list over the translucent app background |
| 2026-06-06 | Interaction conventions | Added a maintained haptic rule for dropdown-style controls: subtle selection feedback on open and on item choice for popup selectors, popup action menus, and form dropdowns | Aligns the shared interaction contract with the new app-wide dropdown haptic behavior |
| 2026-06-06 | Shared primitives and core components | Added `AppAnchoredPopoverMenuItem` as the shared selected-row treatment for anchored selector menus and aligned language/timezone selectors to use it | Prevents selector-menu styling drift now that anchored popovers are the maintained menu path for compact and settings-style selectors |
| 2026-06-06 | Core components and interaction conventions | Added `AppListRow`, `AppSwitchRow`, and `AppChip` to the maintained shared-widget layer and documented the primitive/composite/domain extraction threshold | Keeps repeated Flutter controls consistent while preventing over-abstraction of richer domain-specific UI like readiness and RSVP |
| 2026-06-06 | Interaction conventions | Added the maintained confirmation-dialog threshold and shared mobile haptics contract for meaningful toggles, successful commits, refresh completion, and confirmed destructive/session-ending actions | Keeps cross-app feedback behavior intentional and consistent without adding blanket confirmation friction or noisy tactile feedback |
| 2026-06-06 | Motion rules | Switched the maintained production ambient baseline from one shared value to a renderer-aware contract: native shader `0.0`, web/fallback `0.8` | Matches the observed runtime behavior where the native fragment shader remains visible at zero intensity while web/fallback still need the stronger baseline |
| 2026-06-06 | Motion rules | Refined the focused transparent-flow handoff to use a delayed incoming reveal after the covered route starts fading, while keeping the shader loop contract explicitly periodic | Further reduces auth-screen dark-film overlap while preserving the seam-free ambient cycle contract |
| 2026-06-06 | Motion rules | Made the shared shader loop contract explicitly periodic at cycle boundaries and clarified that focused transparent flows should not fade the incoming route as a whole | Fixes the visible ambient loop seam and removes post-transition brightness kicks on auth-style transparent pages |
| 2026-06-06 | Motion rules | Strengthened the native-mobile shader chroma and switched the blob contract toward more organic distorted silhouettes while keeping the web fallback untouched | Keeps the restored native shader visibility feeling intentional and natural instead of pale or oddly geometric |
| 2026-06-06 | Motion rules | Added a debug-only ambient shader diagnostic mode and scrim bypass toggle to the shared overlay contract | Makes on-device shader investigations conclusive by separating shader visibility from scrim/compositing without changing release behavior |
| 2026-06-06 | Motion rules | Tightened the native-mobile shader blob profile with stronger motion and more localized highlights while keeping the web fallback untouched | Makes the ambient shader read as visible moving cyan/purple spots on phones instead of a vague overall darkening |
| 2026-06-06 | Motion rules | Added a mobile-native-only shader visibility boost on top of the shared ambient intensity while leaving the web fallback path unchanged | Restores visible ambient shader presence on iPhone-sized screens without regressing the already-good web background rendering |
| 2026-06-06 | Brand asset contract | Clarified that `InGameLogo` must render the canonical logo asset without extra runtime corner clipping | Prevents shared brand-mark usage from shaving off the source logo's rounded corners in reused Flutter UI placements |
| 2026-06-06 | Motion rules | Raised the maintained production ambient baseline to `0.8` so release builds match the intended expressive shader/orb visibility target on smaller screens | Keeps the written visual contract aligned with the stronger production baseline used across web and mobile |
| 2026-06-07 | Motion rules | Clarified that the ambient debug overlay's outer card starts collapsed by default while keeping the maintained `1x` slowdown baseline | Reduces developer-surface distraction on load without changing the available motion and shader controls once expanded |
| 2026-06-05 | Interaction conventions and motion rules | Documented the Cupertino-preserving iOS fade route, clarified that indexed-shell branch switches remain immediate while pushed pages animate, and added the production ambient baseline plus truthful renderer diagnostics contract | Aligns the written platform-motion contract with the production follow-up fixes for iOS overlap, ambient visibility, and the verified Windows web route matrix |
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
