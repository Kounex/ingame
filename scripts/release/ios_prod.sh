#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

API_BASE_URL="${INGAME_API_BASE_URL:-https://api.in-game.app/api/v1}"
WEB_APP_BASE_URL="${INGAME_WEB_APP_BASE_URL:-https://app.in-game.app}"
INVITE_BASE_URL="${INGAME_INVITE_BASE_URL:-https://in-game.app}"
DISCORD_CLIENT_ID="${DISCORD_CLIENT_ID:-}"

MODE="run"
if [[ "${1:-}" == "--build" ]]; then
  MODE="build"
  shift
fi

cd "${REPO_ROOT}"

if [[ "${MODE}" == "build" ]]; then
  flutter build ipa \
    --release \
    --dart-define="INGAME_API_BASE_URL=${API_BASE_URL}" \
    --dart-define="INGAME_WEB_APP_BASE_URL=${WEB_APP_BASE_URL}" \
    --dart-define="INGAME_INVITE_BASE_URL=${INVITE_BASE_URL}" \
    --dart-define="DISCORD_CLIENT_ID=${DISCORD_CLIENT_ID}" \
    "$@"
else
  flutter run \
    --release \
    --device-timeout 10 \
    --dart-define="INGAME_API_BASE_URL=${API_BASE_URL}" \
    --dart-define="INGAME_WEB_APP_BASE_URL=${WEB_APP_BASE_URL}" \
    --dart-define="INGAME_INVITE_BASE_URL=${INVITE_BASE_URL}" \
    --dart-define="DISCORD_CLIENT_ID=${DISCORD_CLIENT_ID}" \
    "$@"
fi
