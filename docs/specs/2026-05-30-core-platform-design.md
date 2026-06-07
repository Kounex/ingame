---
spec: core-platform
version: "3.3"
status: complete
last_updated: "2026-06-07"
sub_project: 1
---

# InGame -- Core Platform Overview Spec

> Part of the [InGame Product Roadmap](roadmap.md)

## Overview

InGame is a social gaming coordination app that makes it easier to find time to play with friends. SP1: Core Platform is the foundational layer that later sub-projects depend on. It establishes:

- authentication and identity
- user profiles and onboarding
- groups, memberships, invites, and join requests
- shared Flutter architecture and UI conventions
- deployment, testing, and API-contract foundations

This file is now the SP1 entry point. Detailed contracts live in focused child specs linked below.

---

## Target Platforms

- iOS (App Store)
- Android (Play Store)
- Web

---

## Spec Set

SP1 is now split into one overview plus focused child specs:

- [Core Platform Auth](2026-05-30-core-platform-auth.md) -- sign-in methods, token/session lifecycle, recovery email rules, provider linking, platform callback configuration
- [Core Platform Social Identities](2026-06-07-core-platform-social-identities.md) -- provider capability matrix, normalized linked identities, refresh rules, and manual social-platform fallbacks
- [Core Platform Profiles](2026-05-30-core-platform-profiles.md) -- user profile fields, avatar rules, onboarding profile setup, profile editing, recurring availability
- [Core Platform Groups](2026-05-30-core-platform-groups.md) -- groups, memberships, invites, discoverability, join requests, RBAC
- [Core Platform Implementation](2026-05-30-core-platform-implementation.md) -- Flutter structure, shared app boundaries, design system, navigation, localization, and testing conventions

Use this overview when you need the shared SP1 picture. Use the child specs when you need a precise contract for one area.

---

## Shared Technical Baseline

### Frontend

- Flutter 3.44 / Dart 3.12
- Riverpod
- GoRouter
- Freezed
- Dio
- Flutter localization stack (`flutter_localizations + intl + gen_l10n`)

### Backend

- FastAPI
- PostgreSQL 16
- Redis 7
- SQLAlchemy async
- Pydantic v2
- JWT access + refresh tokens

### DevOps

- Docker Compose for local development
- OpenShift + ArgoCD for deployment
- CI/CD for lint, test, image build, and contract validation

---

## System Architecture

```text
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
 memberships)  pub/sub)    Avatar storage,
                           Push: FCM/APNs)
```

Shared architecture assumptions:

- one FastAPI service handles both REST and WebSocket surfaces
- all Flutter clients share the same API contract
- Redis backs session and realtime state
- PostgreSQL persists durable relational data
- object storage is used for uploaded avatars, while the database stores only URLs

---

## What Lives In Each Child Spec

### Auth

See [Core Platform Auth](2026-05-30-core-platform-auth.md) for:

- supported sign-in methods
- token and session behavior
- recovery email rules
- provider linking and unlinking
- platform callback configuration

### Profiles

See [Core Platform Profiles](2026-05-30-core-platform-profiles.md) for:

- user profile fields
- avatar upload and URL rules
- onboarding profile setup
- profile editing
- recurring availability persistence

### Social Identities

See [Core Platform Social Identities](2026-06-07-core-platform-social-identities.md) for:

- auth-provider versus social-identity boundaries
- normalized linked provider identities
- refreshable official provider metadata
- manual provider fields for Xbox, PlayStation, and Nintendo
- outbound social/profile actions

### Groups

See [Core Platform Groups](2026-05-30-core-platform-groups.md) for:

- group, membership, and join-request models
- RBAC
- invites and discoverability
- contract-sensitive group preview fields such as `member_count` and `has_pending_join_request`
- group detail and settings behavior

### Implementation

See [Core Platform Implementation](2026-05-30-core-platform-implementation.md) for:

- feature-first Flutter structure
- shared app boundaries
- design-system rules
- navigation conventions
- localization, failure-handling, and testing patterns

---

## Cross-Cutting Contracts

### Spec-Driven Development

SP1 remains spec-driven. Code changes that affect API shape, data models, navigation, user flows, shared widgets, or architecture must update the relevant spec in the same response.

### API Contract

Backend Pydantic schemas remain the source of truth. Flutter models and repositories must match those response shapes. Stable business-rule error codes continue to be part of the contract.

Contract-sensitive SP1 response details that child specs must keep in sync include:

- `GroupResponse.has_pending_join_request` so discover and invite-preview surfaces render approval CTA state from backend truth instead of widget-local memory

### Localization

User-facing Flutter copy remains localized through the ARB catalogs in `lib/l10n/`. Shared widgets, helper text, dialogs, toasts, and error messaging are included in that rule.

### Design System

The SP1 app shell continues to use the glassmorphism design system and Cue-backed shared motion surfaces defined in the implementation spec.

---

## Testing And Delivery

### Testing Strategy

- Flutter uses repository/provider tests plus focused widget tests for screens and shared components
- backend uses API and realtime tests
- CI validates lint, tests, API contract alignment, and spec freshness

### Deployment Baseline

- local development uses Docker Compose with PostgreSQL, Redis, API, and web runtimes
- production uses OpenShift + ArgoCD with separate Helm charts for `ingame-api` and `ingame-web`
- invite-link hosting, browser app hosting, and API hosting may be split across `in-game.app`, `app.in-game.app`, and `api.in-game.app`
- `GET /health` remains the deployment health endpoint

---

## Change Log

| Date | Section | Change | Reason |
|------|---------|--------|--------|
| 2026-06-04 | Spec topology | Converted the original oversized SP1 spec into a thin overview plus focused auth, profiles, groups, and implementation child specs | Keeps SP1 maintainable as the project grows while preserving one stable entry-point spec path |
| 2026-06-04 | Naming normalization | Reframed the SP1 implementation-facing child spec from `UI Architecture` to `Implementation` | Aligns SP1 and SP2 naming with less ambiguity about what belongs in the implementation-oriented child spec |
| 2026-06-07 | Groups and API contract | Added the backend-truth `GroupResponse.has_pending_join_request` preview field to the SP1 overview contract summary | Keeps the overview spec aligned with the maintained group preview API so contract validation reads the same join-request state now used by discover and invite flows |
| 2026-06-07 | Social identity child spec | Added a dedicated SP1 child spec for social identities and linked it from the overview | Creates a stable home for the new provider-capability and linked-identity contract without overloading the auth or profiles specs |
