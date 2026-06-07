#!/usr/bin/env bash

if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

WEB_DEV_PORT="${INGAME_WEB_DEV_PORT:-8090}"
API_BASE_URL="${INGAME_API_BASE_URL:-http://localhost:8000/api/v1}"
WEB_APP_BASE_URL="${INGAME_WEB_APP_BASE_URL:-http://localhost:${WEB_DEV_PORT}}"
INVITE_BASE_URL="${INGAME_INVITE_BASE_URL:-http://localhost:${WEB_DEV_PORT}}"
DISCORD_CLIENT_ID="${DISCORD_CLIENT_ID:-}"
APPLE_SERVICE_ID="${APPLE_SERVICE_ID:-com.kounex.ingame.web}"

cd "${REPO_ROOT}"

flutter run \
  -d chrome \
  --web-port="${WEB_DEV_PORT}" \
  --dart-define="INGAME_API_BASE_URL=${API_BASE_URL}" \
  --dart-define="INGAME_WEB_APP_BASE_URL=${WEB_APP_BASE_URL}" \
  --dart-define="INGAME_INVITE_BASE_URL=${INVITE_BASE_URL}" \
  --dart-define="DISCORD_CLIENT_ID=${DISCORD_CLIENT_ID}" \
  --dart-define="APPLE_SERVICE_ID=${APPLE_SERVICE_ID}" \
  "$@"
