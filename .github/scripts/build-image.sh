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

# Pack only CONTEXT and DOCKERFILE into a tarball so the Cloud Build upload
# stays small (repo root is ~739MB; a per-image tarball is roughly the size
# of CONTEXT). Uploading a tarball also bypasses .gcloudignore, giving us
# exact control over what's shipped.
tarball=$(mktemp --suffix=.tar.gz)
uncompressed=$(mktemp --suffix=.tar)
trap 'rm -f "$tarball" "$uncompressed"' EXIT

# Entries keep their repo-relative paths so cloudbuild.yaml's
# `docker buildx build "$CONTEXT" -f "$DOCKERFILE"` (both /workspace-relative)
# still resolves after extraction. CONTEXT's own .dockerignore (if any) is
# honored here too — otherwise e.g. frontend/node_modules would ride along
# despite never being COPYed into the image. Packed in two stages, CONTEXT
# then DOCKERFILE appended separately, because tar's --exclude-from applies
# to the whole invocation rather than just the entry beside it — a single
# `tar ... --exclude-from=... "$CONTEXT" "$DOCKERFILE"` call would risk
# silently dropping DOCKERFILE if a future .dockerignore pattern happens to
# match part of its path too.
exclude_args=()
if [ -f "$CONTEXT/.dockerignore" ]; then
  exclude_args+=(--exclude-from="$CONTEXT/.dockerignore")
fi
tar -cf "$uncompressed" -C . "${exclude_args[@]}" "$CONTEXT"
tar -rf "$uncompressed" -C . "$DOCKERFILE"
gzip -c "$uncompressed" >"$tarball"

# --gcs-source-staging-dir must be explicit: gcloud's auto-detected staging
# path fails with "forbidden from accessing the bucket" when the caller is a
# service account (confirmed by reproducing locally with and without this
# flag, identical caller/bucket/IAM otherwise).
gcloud builds submit "$tarball" \
  --project="${PROJECT_ID}" \
  --region="${REGION}" \
  --gcs-source-staging-dir="gs://${PROJECT_ID}_cloudbuild/source" \
  --config=cloudbuild.yaml \
  --service-account="projects/${PROJECT_ID}/serviceAccounts/${BUILD_SA}" \
  --substitutions="_CONTEXT=${CONTEXT},_DOCKERFILE=${DOCKERFILE},_REF=${REF},_CACHE=${CACHE}"
