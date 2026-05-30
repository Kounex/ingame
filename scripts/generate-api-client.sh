#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SPEC_URL="${1:-http://localhost:8000/api/v1/openapi.json}"
OUTPUT_DIR="$PROJECT_ROOT/lib/generated"

echo "Fetching OpenAPI spec from $SPEC_URL..."
curl -sf "$SPEC_URL" -o /tmp/ingame-openapi.json

echo "Generating Dart client..."
openapi-generator generate \
  -i /tmp/ingame-openapi.json \
  -g dart-dio \
  -o "$OUTPUT_DIR" \
  --additional-properties=pubName=ingame_api,pubAuthor=InGame

echo "Running build_runner for generated code..."
cd "$PROJECT_ROOT"
dart run build_runner build --delete-conflicting-outputs

echo "API client generated at $OUTPUT_DIR"
