---
spec: marketing-site
version: "1.5"
status: active
last_updated: "2026-06-04"
sub_project: Marketing Site
---

# Marketing Site Design

## Goal

Build a production-ready marketing website for `https://in-game.app` that presents InGame as a premium social gaming coordination product while preserving base-domain deep-link verification and canonical join-link behavior.

## Scope

The marketing site is a standalone Astro project under `marketing/site/` with:

- static HTML export to `dist/`
- Tailwind CSS and TypeScript
- a responsive landing page plus legal placeholder pages
- `/.well-known/apple-app-site-association`
- `/.well-known/assetlinks.json`
- an nginx config that serves the site and proxies `/join/*` to `http://app:8080`

## Product Positioning

Marketing copy must stay aligned with shipped product capabilities only:

- email/password, Steam, and Apple authentication
- onboarding and profiles
- private groups
- invite links and join requests
- real-time coordination foundations

The site should frame web and native as one product:

- web for instant access
- iOS and Android as the preferred native mobile experience
- native especially valuable for notification-driven coordination

## Visual System

The site must reuse the app's visual language:

- dark glassmorphism surfaces
- `Inter` typography
- `#0A0E1A` background
- `#151B2E` raised surfaces
- `#4FC3F7` primary accent
- `#B388FF` secondary accent
- the same cyan-to-violet gradient treatment for the `InGame` wordmark

## Deployment Contract

The production host split remains:

- marketing site: `https://in-game.app`
- browser app: `https://app.in-game.app`
- API: `https://api.in-game.app`

The marketing nginx layer must:

- serve static marketing routes directly
- serve `/.well-known/*` directly
- proxy `/join/*` to the browser app with `Host: app.in-game.app`
- ship as a standalone nginx config that can be syntax-checked locally without depending on external include files

The marketing project's `public/.well-known/*` files must mirror the canonical app-link files already tracked in `web/.well-known/*` so base-domain hosting does not drift from the mobile deep-link identifiers and path contract.

The deployment pipeline must also include a dedicated marketing runtime image and compose runtime:

- build `Dockerfile.marketing`
- publish `ghcr.io/<owner>/ingame-marketing`
- add `marketing` to the local and release Compose stacks
- expose the marketing runtime separately from the browser app runtime so different external tunnel or ingress providers can route `in-game.app` and `app.in-game.app` independently

## Change Log

| date | section | what changed | why |
|------|---------|--------------|-----|
| 2026-06-04 | initial | Added the standalone marketing site spec covering Astro structure, app-aligned branding, and nginx join-link proxying | Tracks the new base-domain marketing surface in the maintained spec set |
| 2026-06-04 | deployment contract | Clarified that `marketing/site/public/.well-known/*` must mirror the canonical files in `web/.well-known/*` | Prevents the base-domain marketing host from drifting away from the verified mobile deep-link identifiers |
| 2026-06-04 | nginx config | Clarified that the marketing nginx file should be self-contained enough for local syntax validation outside the final container network | Keeps deployment config easier to verify during local development |
| 2026-06-04 | image and compose runtime | Added the dedicated marketing image and Compose runtime contract for local and release deployment, with the generic file name `docker-compose.release.yml` | Makes `in-game.app` deployable as a first-class runtime alongside `api` and `app` without baking a platform-specific deployment name into the repo |
| 2026-06-04 | deployment wording | Removed provider-specific tunnel wording from the deployment contract | Keeps the public repo deployment guidance provider-neutral |
