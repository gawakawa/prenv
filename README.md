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

### 1. Bootstrap IAP (manual — Console only)

Preview environments are protected by [Identity-Aware Proxy (IAP)](https://cloud.google.com/iap/docs/enabling-cloud-run).
For projects without a Google Cloud organization, the OAuth consent screen and IAP OAuth client
must be created via the Console before Terraform can manage IAP:

1. **Configure the OAuth consent screen**: Console → APIs & Services → OAuth consent screen.
   Select **External**, fill in the required fields, and add your Google account email as a
   **Test user**. Save and continue through all steps.

2. **Bootstrap the IAP OAuth client**: Console → Security → Identity-Aware Proxy. Enable IAP
   on any Cloud Run service (a temporary service is fine). This auto-creates the project-level
   OAuth client and the IAP service agent
   (`service-PROJECT_NUMBER@gcp-sa-iap.iam.gserviceaccount.com`). Both persist at the project
   level after the service is deleted.

3. **Do this before the first `tofu apply` of the ephemeral module** — Terraform's `iap_enabled`
   reuses the project OAuth client created in step 2. Applying without it will fail.

### 2. Apply the shared foundation

```bash
cd terraform/shared
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set project_id, state_bucket_name, github_repository, iap_members
tofu init
tofu apply -var-file=terraform.tfvars
```

Set `iap_members` to the list of Google accounts that should have access to preview
environments, e.g. `iap_members = ["user:you@example.com"]`.

### 3. Apply the PR preview base

```bash
cd terraform/env/pr/base
# Reuse the same terraform.tfvars values (project_id is sufficient)
tofu init
tofu apply -var project_id=<your-project-id>
```

### 4. Set GitHub Actions variables

Create a GitHub Actions Environment named **`pr`**: GitHub → Settings → Environments → New environment → name it `pr`.

> **Do not add protection rules** (required reviewers, wait timer, etc.) — they would block the automatic teardown when a PR is closed.

From the `tofu output` values, add these as **Environment variables** inside the `pr` environment:

| Variable | Source |
|---|---|
| `WIF_PROVIDER` | `cd terraform/shared && tofu output -raw wif_provider_name` |
| `DEPLOY_SA` | `cd terraform/shared && tofu output -raw deploy_service_account_email` |
| `GCP_PROJECT_ID` | your Google Cloud project ID |
| `GCS_BUCKET` | `cd terraform/shared && tofu output -raw state_bucket_name` |
| `AR_REPO` | `cd terraform/env/pr/base && tofu output -raw repository_url` |

### 5. Create the `preview` label

In GitHub → Issues → Labels, create a label named `preview`.

## Usage

Add the `preview` label to a PR. GitHub Actions will:
1. Build the Docker image from `app/` and push it to Artifact Registry.
2. Run `tofu apply` in `terraform/env/pr/ephemeral/` to deploy a Cloud Run service.
3. Post the `*.run.app` preview URL as a PR comment.

Close the PR and Actions tears the environment down automatically. Stale environments (state not updated in 3+ days) are also swept by the daily GC cron.