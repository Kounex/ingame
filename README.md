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
- Docker or Podman with Compose
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
- MinIO S3 API on `http://localhost:9000`
- MinIO Console on `http://localhost:9001`

The compose stack applies the latest API migrations on startup, bootstraps a
public `ingame-avatars` bucket, and starts MinIO with browser-upload CORS
enabled so avatar uploads work locally without extra manual setup.

### Run the Flutter app natively

```bash
flutter pub get
flutter run
```

By default, Flutter runtime hosts stay repo-local for development:

- `INGAME_API_BASE_URL=http://localhost:8000/api/v1`
- `INGAME_WEB_APP_BASE_URL=http://localhost:8080`
- `INGAME_INVITE_BASE_URL=http://localhost:8080`

Optional social-login build flags:

- `DISCORD_CLIENT_ID=<your Discord application client id>` enables the Discord sign-in button and OAuth flow in Flutter/web builds
- `APPLE_SERVICE_ID=com.kounex.ingame.web` enables Apple Sign-In on web builds

On this machine, the recommended local place for personal overrides is `~/.localrc`
if your shell already sources it. For Discord, add:

```bash
export INGAME_DISCORD_CLIENT_ID=<your-discord-client-id>
export DISCORD_CLIENT_ID=<your-discord-client-id>
```

If you want the native app to target a different backend, browser-app host, or invite host:

```bash
flutter run \
  --dart-define=INGAME_API_BASE_URL=http://localhost:8000/api/v1 \
  --dart-define=INGAME_WEB_APP_BASE_URL=http://localhost:8080 \
  --dart-define=INGAME_INVITE_BASE_URL=http://localhost:8080 \
  --dart-define=DISCORD_CLIENT_ID=<your-discord-client-id>
```

For a local Chrome run that uses your current shell environment, pins Flutter
Chrome to a predictable local port, and forwards the local host defines plus web
social-login flags, use:

```bash
./scripts/release/chrome_local.sh
```

By default, that helper uses `http://localhost:8090` for the browser app so it
does not collide with the containerized `ingame-web` runtime on `8080` or the
local marketing runtime on `8081`. Override the port if needed:

```bash
INGAME_WEB_DEV_PORT=8091 ./scripts/release/chrome_local.sh
```

### Backend setup without Compose

```bash
python3 -m pip install -r backend/requirements.txt
python3 -m uvicorn app.main:app --app-dir backend --host 0.0.0.0 --port 8000 --reload
```

Optional backend auth-provider config:

- `INGAME_DISCORD_CLIENT_ID=<your Discord application client id>`
- `INGAME_APPLE_CLIENT_IDS=ingame.kounex.com,com.kounex.ingame.web`

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

Local compose wires MinIO automatically. `docker-compose.release.yml` now also
includes bundled MinIO by default for self-hosted deployments, while the same
API contract can still point at a different external S3-compatible store if you
intentionally customize the stack.

Avatar uploads require runtime values for:

- `INGAME_AVATAR_STORAGE_BUCKET`
- `INGAME_AVATAR_STORAGE_REGION` (set a real region for AWS S3 or any region-sensitive backend; local MinIO uses `auto`)
- `INGAME_AVATAR_STORAGE_ENDPOINT_URL`
- `INGAME_AVATAR_STORAGE_UPLOAD_BASE_URL` (optional when the browser uploads through a different public host than the API uses internally)
- `INGAME_AVATAR_STORAGE_ACCESS_KEY_ID`
- `INGAME_AVATAR_STORAGE_SECRET_ACCESS_KEY`
- `INGAME_AVATAR_STORAGE_PUBLIC_BASE_URL`

These avatar-storage and MinIO values are backend/runtime configuration only.
Flutter does not have a separate MinIO `--dart-define`; it talks to the API and
uses the backend-provided `upload_url` / `avatar_url` contract.

If those are intentionally left unset, `POST /api/v1/users/me/avatar-upload/init`
will return the structured fallback `503 user.avatar_upload_unavailable`.

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

### iOS production build

Use the iOS production wrapper so production hosts are opt-in instead of baked into the
repo defaults:

```bash
./scripts/release/ios_prod.sh -d <device-id>
```

Without `--build`, the wrapper runs `flutter run`. With `--build`, it switches
to `flutter build ipa`.

The wrapper passes:

- `INGAME_API_BASE_URL=https://api.in-game.app/api/v1`
- `INGAME_WEB_APP_BASE_URL=https://app.in-game.app`
- `INGAME_INVITE_BASE_URL=https://in-game.app`

Build an IPA instead of running on a connected device:

```bash
./scripts/release/ios_prod.sh --build
```

You can override any of them for another environment, for example:

```bash
INGAME_API_BASE_URL=https://api.example.com/api/v1 \
INGAME_WEB_APP_BASE_URL=https://app.example.com \
INGAME_INVITE_BASE_URL=https://example.com \
./scripts/release/ios_prod.sh --build
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
- local S3-compatible avatar storage via MinIO
- local web runtime verification
- validating `/.well-known/*` hosting behavior

`docker-compose.release.yml` is the release-image equivalent for Docker-hosted or
Podman-hosted installs without bundled ingress. It supports:

- the default API + web + marketing + PostgreSQL + Redis stack
- bundled MinIO + bucket bootstrap for self-hosted avatar uploads
- externally managed S3-compatible avatar storage via environment variables

The release MinIO bootstrap is inlined directly in the compose service so
Portainer stack deployments do not depend on mounting repo-side helper files,
and the bootstrap runs through an explicit `/bin/sh -ec` entrypoint so the
`minio/mc` image does not try to interpret the shell command as an `mc`
subcommand.

When using the bundled MinIO release stack, point the API at the bundled service and
provide a browser-reachable public base URL. A typical self-hosted `.env` pairing is:

```bash
INGAME_AVATAR_STORAGE_BUCKET=ingame-avatars
INGAME_AVATAR_STORAGE_REGION=auto
INGAME_AVATAR_STORAGE_ENDPOINT_URL=http://minio:9000
INGAME_AVATAR_STORAGE_UPLOAD_BASE_URL=https://assets.example.com
INGAME_AVATAR_STORAGE_ACCESS_KEY_ID=ingame
INGAME_AVATAR_STORAGE_SECRET_ACCESS_KEY=replace-me
INGAME_AVATAR_STORAGE_PUBLIC_BASE_URL=https://assets.example.com/ingame-avatars
```

If you use the bundled MinIO release stack on a non-`app.in-game.app` host,
set `MINIO_API_CORS_ALLOW_ORIGIN` to the browser origin you actually serve the
app from, or leave the compose default `*` in place for a broad self-hosted setup.

Then start the release stack with:

```bash
podman compose -f docker-compose.release.yml up -d
```

#### Pre-release data policy

Until the app has live production data or an explicit `1.0`-style release,
prefer clean schema migrations over shipping legacy compatibility code for old
stack data. If a pre-release feature change is large enough that a migration is
not worth the complexity, document an explicit PostgreSQL data reset / volume
wipe for self-hosted stacks instead of carrying transitional runtime code.

For Docker or Portainer-hosted updates, always state which path applies:

- run `alembic upgrade head` by restarting the `api` service with the updated stack
- wipe the PostgreSQL volume and redeploy when the feature intentionally starts from a clean database

After the first live release with real user data, treat backward compatibility
as required by default and prefer database migrations unless an exception is
explicitly approved.

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
