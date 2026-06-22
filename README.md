# Terraform Module

## Overview

A Google Cloud version of the preview environment setup in [this blog post](https://www.m3tech.blog/entry/2026/06/16/153849).

For each PR, provision an isolated, ephemeral preview environment on Google Cloud with Terraform + Cloud Run, then tear it down when the PR is closed.

## Structure

- `terraform/shared/` — shared foundation: APIs, state bucket, Workload Identity Federation, deploy service account. Apply **once locally**.
- `terraform/env/pr/base/` — PR preview shared resources: Artifact Registry repository. Apply **once locally**.
- `terraform/env/pr/ephemeral/` — per-PR preview environment: one Cloud Run service. Applied/destroyed automatically by GitHub Actions.
- `app/` — minimal sample app (Go HTTP server) with Dockerfile.
- `.github/workflows/preview-deploy.yml` — builds and deploys a preview when the `preview` label is added to a PR.
- `.github/workflows/preview-teardown.yml` — destroys the preview when the PR is closed, on a daily GC of stale environments, or manually.

## One-time setup

### 1. Apply the shared foundation

```bash
cd terraform/shared
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set project_id, state_bucket_name, github_repository
tofu init
tofu apply -var-file=terraform.tfvars
```

### 2. Apply the PR preview base

```bash
cd terraform/env/pr/base
# Reuse the same terraform.tfvars values (project_id is sufficient)
tofu init
tofu apply -var project_id=<your-project-id>
```

### 3. Set GitHub Actions variables

From the `tofu output` values, set these as **repository variables** (not secrets) in GitHub → Settings → Secrets and variables → Actions → Variables:

| Variable | Source |
|---|---|
| `WIF_PROVIDER` | `cd terraform/shared && tofu output -raw wif_provider_name` |
| `DEPLOY_SA` | `cd terraform/shared && tofu output -raw deploy_service_account_email` |
| `GCP_PROJECT_ID` | your Google Cloud project ID |
| `GCS_BUCKET` | `cd terraform/shared && tofu output -raw state_bucket_name` |
| `AR_REPO` | `cd terraform/env/pr/base && tofu output -raw repository_url` |

### 4. Create the `preview` label

In GitHub → Issues → Labels, create a label named `preview`.

## Usage

Add the `preview` label to a PR. GitHub Actions will:
1. Build the Docker image from `app/` and push it to Artifact Registry.
2. Run `tofu apply` in `terraform/env/pr/ephemeral/` to deploy a Cloud Run service.
3. Post the `*.run.app` preview URL as a PR comment.

Close the PR and Actions tears the environment down automatically. Stale environments (state not updated in 3+ days) are also swept by the daily GC cron.