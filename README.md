# Terraform Module

## Overview

A Google Cloud version of the preview environment setup in [this blog post](https://www.m3tech.blog/entry/2026/06/16/153849).

For each PR, provision an isolated, ephemeral preview environment on Google Cloud with Terraform + Cloud Run, then tear it down when the PR is closed.

## Structure

- `terraform/shared/` — shared foundation: APIs, state bucket, Workload Identity Federation, deploy service account. Apply **once locally**.
- `terraform/env/pr/` — per-PR preview environment: one Cloud Run service. Applied/destroyed automatically by GitHub Actions.
- `.github/workflows/preview-deploy.yml` — deploys a preview when the `preview` label is added to a PR (and on each push while labeled).
- `.github/workflows/preview-teardown.yml` — destroys the preview when the PR is closed.

## One-time setup

### 1. Apply the foundation

```bash
cd terraform/shared
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set project_id, state_bucket_name, github_repository
tofu init
tofu apply -var-file=terraform.tfvars
```

### 2. Set GitHub Actions variables

From the `tofu output` values, set these as **repository variables** (not secrets) in GitHub → Settings → Secrets and variables → Actions → Variables:

| Variable | Value |
|---|---|
| `WIF_PROVIDER` | `tofu output -raw wif_provider_name` |
| `DEPLOY_SA` | `tofu output -raw deploy_service_account_email` |
| `GCP_PROJECT_ID` | your Google Cloud project ID |
| `GCS_BUCKET` | `tofu output -raw state_bucket_name` |

### 3. Create the `preview` label

In GitHub → Issues → Labels, create a label named `preview`.

## Usage

Add the `preview` label to a PR. GitHub Actions will:
1. Run `tofu apply` in `terraform/env/pr/` with state prefix `pr/<N>`.
2. Post the `*.run.app` preview URL as a PR comment.

Close the PR or remove the `preview` label, and Actions tears the environment down automatically.