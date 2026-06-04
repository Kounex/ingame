#!/bin/sh
set -eu

MINIO_ALIAS="${MINIO_ALIAS:-local}"
MINIO_ENDPOINT_URL="${MINIO_ENDPOINT_URL:?MINIO_ENDPOINT_URL is required}"
MINIO_ROOT_USER="${MINIO_ROOT_USER:?MINIO_ROOT_USER is required}"
MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:?MINIO_ROOT_PASSWORD is required}"
MINIO_BUCKET="${MINIO_BUCKET:?MINIO_BUCKET is required}"
until mc alias set "$MINIO_ALIAS" "$MINIO_ENDPOINT_URL" "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null 2>&1; do
  echo "Waiting for MinIO at $MINIO_ENDPOINT_URL..."
  sleep 2
done

mc mb --ignore-existing "$MINIO_ALIAS/$MINIO_BUCKET"
mc anonymous set download "$MINIO_ALIAS/$MINIO_BUCKET"

echo "MinIO bucket bootstrap complete for $MINIO_BUCKET"
