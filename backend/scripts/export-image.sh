#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${1:-synthia-backend}"
TAG="${2:-latest}"
REGISTRY="${REGISTRY:-registry.coolify.io}"

if [ -z "${GOOGLE_PROJECT_ID:-}" ]; then
  echo "GOOGLE_PROJECT_ID env var not set. Export script requires project context." >&2
  exit 1
fi

FULL_IMAGE_NAME="gcr.io/${GOOGLE_PROJECT_ID}/${IMAGE_NAME}:${TAG}"

if ! command -v gcloud >/dev/null 2>&1; then
  echo "gcloud CLI is required" >&2
  exit 1
fi

echo "Pulling ${FULL_IMAGE_NAME} from Google Artifact Registry..."
gcloud auth configure-docker -q

docker pull "${FULL_IMAGE_NAME}"

echo "Retagging image for ${REGISTRY}"
docker tag "${FULL_IMAGE_NAME}" "${REGISTRY}/${IMAGE_NAME}:${TAG}"

echo "Pushing image to ${REGISTRY}"
docker push "${REGISTRY}/${IMAGE_NAME}:${TAG}"
