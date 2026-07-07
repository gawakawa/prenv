#!/usr/bin/env bash
# Submit a single-image Cloud Build job, skipping if the image already exists.
# Usage: build-image.sh <context> <dockerfile> <ref> <cache: yes|no>
#   context    - Docker build context directory
#   dockerfile - path to the Dockerfile
#   ref        - full image reference, e.g. us-docker.pkg.dev/proj/repo/backend:abc123
#   cache      - 'yes' to push/pull a registry build cache, 'no' otherwise
#
# Required env: PROJECT_ID, BUILD_SA
set -euo pipefail

CONTEXT=$1
DOCKERFILE=$2
REF=$3
CACHE=$4

if gcloud artifacts docker images describe "$REF" --quiet >/dev/null 2>&1; then
  echo "skip $REF (already exists)"
  exit 0
fi

gcloud builds submit . \
  --project="${PROJECT_ID}" \
  --config=cloudbuild.yaml \
  --service-account="projects/${PROJECT_ID}/serviceAccounts/${BUILD_SA}" \
  --substitutions="_CONTEXT=${CONTEXT},_DOCKERFILE=${DOCKERFILE},_REF=${REF},_CACHE=${CACHE}"
