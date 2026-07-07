#!/usr/bin/env bash
# Submit a single-image Cloud Build job, skipping if the image already exists.
# Usage: build-image.sh <context> <dockerfile> <ref> <cache: true|false>
#   context    - Docker build context directory
#   dockerfile - path to the Dockerfile
#   ref        - full image reference, e.g. us-docker.pkg.dev/proj/repo/backend:abc123
#   cache      - 'true' to push/pull a registry build cache, 'false' otherwise
#
# Required env: PROJECT_ID, BUILD_SA, REGION
set -euo pipefail

CONTEXT=$1
DOCKERFILE=$2
REF=$3
CACHE=$4

if gcloud artifacts docker images describe "$REF" --quiet >/dev/null 2>&1; then
  echo "skip $REF (already exists)"
  exit 0
fi

# --region must match the Cloud Build staging bucket's location, or the
# request fails with "forbidden from accessing the bucket" (a region/location
# mismatch surfaces as a storage-side 400, not a clear region error).
gcloud builds submit . \
  --project="${PROJECT_ID}" \
  --region="${REGION}" \
  --config=cloudbuild.yaml \
  --service-account="projects/${PROJECT_ID}/serviceAccounts/${BUILD_SA}" \
  --substitutions="_CONTEXT=${CONTEXT},_DOCKERFILE=${DOCKERFILE},_REF=${REF},_CACHE=${CACHE}"
