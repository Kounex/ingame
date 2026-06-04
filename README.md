# InGame

InGame is a social gaming coordination app for finding time to play with friends. It combines a Flutter client, a FastAPI backend, Redis-backed real-time infrastructure, and deployment surfaces for both local development and OpenShift.

## What ships today

- Email/password, Steam, and Apple authentication
- English and German localization via Flutter `gen_l10n`
- First-time onboarding and user profiles
- Groups, invite links, discoverable groups, and join requests
- Real-time transport foundations for presence and coordination
- Split deployment runtimes for:
  - `ingame-api`
  - `ingame-web`

## Repository layout

- `lib/` - Flutter application code
- `test/` - Flutter widget/provider/unit tests
- `backend/` - FastAPI application, models, services, and pytest suite
- `marketing/` - Astro marketing site and nginx config for `in-game.app`
- `deploy/helm/ingame-api/` - Helm chart for the API runtime
- `deploy/helm/ingame-web/` - Helm chart for the web runtime
- `deploy/kustomize/` - environment overlays for dev, staging, and prod
- `scripts/` - CI, release-prep, and helper scripts
- `docs/specs/` - project specs and roadmap
- `.cursor/rules/` - project-specific AI guidance
- `.agents/skills/` - project-local skills, including release prep

## Tech stack

- Flutter 3.44 / Dart 3.12
- `flutter_localizations` + `intl` + `gen_l10n` ARB generation
- FastAPI + SQLAlchemy + PostgreSQL
- Redis for real-time state and fan-out
- Docker Compose for local containers
- Helm + Kustomize + OpenShift Routes for cluster deployment
- GitHub Actions + GHCR for release image publishing

## Local development

### Prerequisites

- Flutter SDK 3.44+
- Python 3.12+ or 3.13
- Docker with Compose
- Helm

### Start backend dependencies and the web runtime

```bash
docker compose up --build
```

This starts:

- API on `http://localhost:8000`
- Web runtime on `http://localhost:8080`
- PostgreSQL on `localhost:5432`
- Redis on `localhost:6379`

### Run the Flutter app natively

```bash
flutter pub get
flutter run
```

If you want the native app to target a different backend, browser-app host, or invite host:

```bash
flutter run \
  --dart-define=INGAME_API_BASE_URL=http://localhost:8000/api/v1 \
  --dart-define=INGAME_WEB_APP_BASE_URL=http://localhost:8080 \
  --dart-define=INGAME_INVITE_BASE_URL=http://localhost:8080
```

### Backend setup without Compose

```bash
python3 -m pip install -r backend/requirements.txt
python3 -m uvicorn app.main:app --app-dir backend --host 0.0.0.0 --port 8000 --reload
```

## Verification

### Flutter

```bash
flutter analyze
flutter test
```

### Backend

```bash
python3 -m pytest backend/tests -q
```

### Helm charts

```bash
helm template ingame-api deploy/helm/ingame-api -f deploy/helm/ingame-api/values.yaml
helm template ingame-web deploy/helm/ingame-web -f deploy/helm/ingame-web/values.yaml
```

## Release workflow

The project uses `pubspec.yaml` as the canonical release version.

### Release prep on `dev`

1. Review what changed and decide the semver bump / release notes:

```bash
python3 -m scripts.release.release_prep_report --base main --head dev
```

2. Update `pubspec.yaml` to the intended release version.
3. Sync backend, Helm, and tracked image refs:

```bash
python3 -m scripts.release.stack_version prepare-release --owner kounex --write
```

4. Commit the release-prep changes on `dev`.
5. Merge `dev` into `main`.
6. Create the tag from `main`:

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

### What the tag workflow does

The `Release Images` GitHub Actions workflow:

- validates that `vX.Y.Z` matches `pubspec.yaml`
- builds and pushes:
  - `ghcr.io/kounex/ingame-api:<version>`
  - `ghcr.io/kounex/ingame-web:<version>`
- also pushes immutable SHA tags

The semver tag is pushed after the SHA tag so GHCR surfaces the release version as the primary pull reference.

## Deployment

### Docker Compose

`docker-compose.yml` is the local/full-stack container entry point. It is intended for:

- local API + DB + Redis development
- local web runtime verification
- validating `/.well-known/*` hosting behavior

### Helm charts

There is no umbrella chart. Deploy the runtimes independently:

- API chart: `deploy/helm/ingame-api/`
- Web chart: `deploy/helm/ingame-web/`

Example renders:

```bash
helm template ingame-api deploy/helm/ingame-api -f deploy/helm/ingame-api/values.yaml
helm template ingame-web deploy/helm/ingame-web -f deploy/helm/ingame-web/values.yaml
```

### Kustomize overlays

`deploy/kustomize/overlays/` contains environment-specific patches for:

- `dev`
- `staging`
- `prod`

The overlays expect rendered output from both charts.

## Invite-link hosting

The public invite-link domain is:

- `https://in-game.app`

The canonical invite-link domain is separate from the browser app host:

- browser SPA: `https://app.in-game.app`
- invite/deep-link host: `https://in-game.app`

For local/full-stack validation, the web runtime can serve:

- the Flutter SPA
- `/.well-known/apple-app-site-association`
- `/.well-known/assetlinks.json`

In production, those invite-link assets may instead be served by a separate base-domain marketing site as long as `https://in-game.app/join/*` and `https://in-game.app/.well-known/*` keep working.

Native invite-link validation is only complete once the Android release certificate fingerprint has been inserted into `web/.well-known/assetlinks.json`.

## Skills and rules

Useful project-local agent assets:

- `.agents/skills/tag-release/SKILL.md`
- `.cursor/rules/localize-user-facing-strings.mdc`
- `.cursor/rules/release-versioning.mdc`
- `.cursor/rules/ghcr-image-conventions.mdc`
- `.cursor/rules/web-deployment-runtime.mdc`

## Current release

- Repository: [github.com/Kounex/ingame](https://github.com/Kounex/ingame)
- Latest release: `v0.3.4`
