# Terraform Module

## Overview

A Google Cloud version of the preview environment setup in [this blog post](https://www.m3tech.blog/entry/2026/06/16/153849).

For each PR, provision an isolated, ephemeral preview environment on Google Cloud with Terraform + Cloud Run, then tear it down when the PR is closed.

## Structure

- `terraform/env/pr/base/` — one-time foundation: state bucket, APIs, Workload Identity Federation, deploy service account, IAP access, Artifact Registry, IAP OAuth secrets. Apply **once locally**.
- `terraform/env/pr/ephemeral/` — per-PR preview environment: one Cloud Run service. Applied/destroyed automatically by GitHub Actions.
- `app/` — minimal sample app (Go HTTP server) with Dockerfile.
- `.github/workflows/preview-deploy.yml` — builds and deploys a preview when the `preview` label is added to a PR.
- `.github/workflows/preview-teardown.yml` — destroys the preview when the PR is closed, on a daily GC of stale environments, or manually.

## One-time setup

### 1. Bootstrap IAP (manual — Console only)

Preview environments are protected by [Identity-Aware Proxy (IAP)](https://cloud.google.com/iap/docs/enabling-cloud-run).
Projects without a Google Cloud organization cannot use the Google-managed IAP OAuth client and
must create a custom one. IAP binding itself cannot be managed by Terraform under this constraint
(`google_iap_settings` does not expose `client_id`/`client_secret`; `google_iap_brand` requires
an org). These steps are one-time manual prerequisites.

1. **Configure the OAuth consent screen**: Console → APIs & Services → OAuth consent screen.
   Select **External**, fill in required fields, and add your Google account as a **Test user**.

2. **Create a custom OAuth client**: Console → APIs & Services → Credentials → Create credentials
   → OAuth client ID → Web application. Under **Authorized redirect URIs**, add:
   ```
   https://iap.googleapis.com/v1/oauth/clientIds/<CLIENT_ID>:handleRedirect
   ```
   (Replace `<CLIENT_ID>` after you save — the ID appears in the credentials list.) Note the
   **Client ID** and **Client secret** for use in `terraform/env/pr/base/terraform.tfvars`.

3. **Bootstrap the IAP service agent**: Console → Security → Identity-Aware Proxy. Toggle IAP on
   for any Cloud Run service (a temporary one is fine). This creates the project-level IAP service
   agent (`service-PROJECT_NUMBER@gcp-sa-iap.iam.gserviceaccount.com`) which persists after the
   service is deleted.

4. **Do this before the first `tofu apply` of the preview modules** — both the service agent
   (step 3) and the OAuth binding (step 5 below) must exist before `iap_enabled = true` works.

### 2. Apply the base foundation

```bash
cd terraform/env/pr/base
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — fill in all values (see terraform.tfvars.example)
tofu init
tofu apply
```

`terraform.tfvars` is gitignored. Set `iap_members` to the Google accounts that should access
preview environments. The `iap_oauth_client_id` and `iap_oauth_client_secret` values come from
Console step 1.2 above. Applying stores the OAuth credentials in Secret Manager.

### 3. Bind the OAuth client to IAP (manual — once after step 2)

`google_iap_settings` does not expose `client_id`/`client_secret`, so IAP binding stays manual.
Create `iap_settings.yaml`:

```yaml
access_settings:
  oauth_settings:
    client_id: <CLIENT_ID>
    client_secret: <CLIENT_SECRET>
```

Then apply:

```bash
gcloud iap settings set iap_settings.yaml --project=<project_id>
```

### 4. Set GitHub Actions variables

Create a GitHub Actions Environment named **`pr`**: GitHub → Settings → Environments → New environment → name it `pr`.

> **Do not add protection rules** (required reviewers, wait timer, etc.) — they would block the automatic teardown when a PR is closed.

From the `tofu output` values, add these as **Environment variables** inside the `pr` environment:

| Variable | Source |
|---|---|
| `WIF_PROVIDER` | `cd terraform/env/pr/base && tofu output -raw wif_provider_name` |
| `DEPLOY_SA` | `cd terraform/env/pr/base && tofu output -raw deploy_service_account_email` |
| `GCP_PROJECT_ID` | your Google Cloud project ID |
| `GCS_BUCKET` | `cd terraform/env/pr/base && tofu output -raw state_bucket_name` |
| `AR_REPO` | `cd terraform/env/pr/base && tofu output -raw repository_url` |

### 5. Create the `preview` label

In GitHub → Issues → Labels, create a label named `preview`.

## Usage

Add the `preview` label to a PR. GitHub Actions will:
1. Build the Docker image from `app/` and push it to Artifact Registry.
2. Run `tofu apply` in `terraform/env/pr/ephemeral/` to deploy a Cloud Run service.
3. Post the `*.run.app` preview URL as a PR comment.

Close the PR and Actions tears the environment down automatically. Stale environments (state not updated in 3+ days) are also swept by the daily GC cron.