#!/usr/bin/env bash
# Submit a single-image Cloud Build job, skipping if the image already exists.
# Usage: build-image.sh <image> <ref>
#   image  - backend | db | frontend
#   ref    - full image reference, e.g. us-docker.pkg.dev/proj/repo/backend:abc123
#
# Required env: PROJECT_ID, BUILD_SA
set -euo pipefail

IMAGE=$1
REF=$2

if gcloud artifacts docker images describe "$REF" --quiet >/dev/null 2>&1; then
  echo "skip $IMAGE ($REF already exists)"
  exit 0
fi

gcloud builds submit . \
  --project="${PROJECT_ID}" \
  --config=cloudbuild.yaml \
  --service-account="projects/${PROJECT_ID}/serviceAccounts/${BUILD_SA}" \
  --substitutions="_IMAGE=${IMAGE},_REF=${REF}"
