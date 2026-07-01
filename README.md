# Terraform Module

## Overview

A Google Cloud version of the preview environment setup in [this blog post](https://www.m3tech.blog/entry/2026/06/16/153849).

## Structure

```
.
├── backend/                sample Go app
├── terraform/env/pr/
│   ├── base/               one-time foundation (apply once locally)
│   └── ephemeral/          per-PR environment (managed by CI)
└── .github/workflows/
    ├── deploy-prenv.yml    deploy on `preview` label
    ├── teardown-prenv.yml  destroy on PR close or manual trigger
    └── gc-prenv.yml        daily GC of stale environments
```

## One-time setup

### 1. Bootstrap IAP (manual — Console only)

1. **Configure the OAuth consent screen**: Console → APIs & Services → OAuth consent screen → External. Add your Google account as a Test user.
2. **Create a custom OAuth client**: Console → APIs & Services → Credentials → OAuth client ID → Web application. Add redirect URI:
   ```
   https://iap.googleapis.com/v1/oauth/clientIds/<CLIENT_ID>:handleRedirect
   ```
   Note the Client ID and Client secret for `terraform/env/pr/base/terraform.tfvars`.
3. **Bootstrap the IAP service agent**: Console → Security → Identity-Aware Proxy. Toggle IAP on for any Cloud Run service once.
4. Complete steps 1–3 before running `tofu apply`.

### 2. Apply the base foundation

```bash
cd terraform/env/pr/base
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — fill in all values (see terraform.tfvars.example)
tofu init
tofu apply
```

### 3. Bind the OAuth client to IAP (manual — once after step 2)

Create `iap_settings.yaml`:

```yaml
access_settings:
  oauth_settings:
    client_id: <CLIENT_ID>
    client_secret: <CLIENT_SECRET>
```

```bash
gcloud iap settings set iap_settings.yaml --project=<project_id>
```

### 4. Set GitHub Actions variables

GitHub → Settings → Environments → New environment → name it `pr`.

> **Do not add protection rules** — they would block automatic teardown when a PR is closed.

Add these as **Environment variables**:

| Variable | Source |
|---|---|
| `WIF_PROVIDER` | `cd terraform/env/pr/base && tofu output -raw wif_provider_name` |
| `DEPLOY_SA` | `cd terraform/env/pr/base && tofu output -raw deploy_service_account_email` |
| `BUILD_SA` | `cd terraform/env/pr/base && tofu output -raw build_service_account_email` |
| `GCP_PROJECT_ID` | your Google Cloud project ID |
| `GCS_BUCKET` | `cd terraform/env/pr/base && tofu output -raw state_bucket_name` |
| `AR_REPO` | `cd terraform/env/pr/base && tofu output -raw repository_url` |

### 5. Create the `preview` label

GitHub → Issues → Labels → create a label named `preview`.

## Usage

### Created

- the `preview` label is added to a PR.

### Destroyed

- the PR is closed.
- the teardown workflow is run manually.
- its state has been idle for 3+ days (swept by the daily GC).
