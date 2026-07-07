---
name: setup-prenv
description: "Onboard the current repository to an existing prenv-managed Google Cloud project: create the preview GitHub environment with six vars, create the preview label, and write trigger workflows plus a Terraform stub that calls prenv's reusable module. Use when the user wants to set up preview environments for a repo or asks to onboard a repo to prenv."
---

# setup-prenv

Onboard the current repository to an existing prenv-managed Google Cloud project.
The project owner has already applied `terraform/base`, added this repo to its
`github_repositories`, and completed the one-time IAP OAuth bootstrap. This skill
only wires up the consuming side.

## Step 1: Get the six values

Ask the user for a local checkout path of the prenv `terraform/base` (or the six
values directly, if they don't have one). If a checkout path is given:

```bash
cd <base_path>
tofu output -json > /tmp/prenv-base-outputs.json
jq -r '.project_id.value, .wif_provider_name.value, .deploy_service_account_email.value, .build_service_account_email.value, .repository_url.value, .state_bucket_name.value' /tmp/prenv-base-outputs.json
```

Map the six outputs to `GCP_PROJECT_ID`, `WIF_PROVIDER`, `DEPLOY_SA`, `BUILD_SA`,
`AR_REPO`, `GCS_BUCKET` in that order.

## Step 2: Create the `preview` GitHub environment and set the six vars

```bash
gh api -X PUT "repos/<OWNER>/<REPO>/environments/preview"
gh variable set GCP_PROJECT_ID --env preview --body "<value>"
gh variable set WIF_PROVIDER   --env preview --body "<value>"
gh variable set DEPLOY_SA      --env preview --body "<value>"
gh variable set BUILD_SA       --env preview --body "<value>"
gh variable set AR_REPO        --env preview --body "<value>"
gh variable set GCS_BUCKET     --env preview --body "<value>"
```

Do not add environment protection rules — they block automatic teardown on PR close.

## Step 3: Create the `preview` label

```bash
gh label create preview --color BFDADC --description "Deploy a preview environment for this PR"
```

## Step 4: Write the trigger workflows

Copy `templates/deploy-prenv.yml`, `templates/teardown-prenv.yml`,
`templates/gc-prenv.yml` verbatim to `.github/workflows/`. They reference
`gawakawa/prenv/.github/workflows/reusable-{deploy,destroy,gc}-prenv.yml` pinned to
a prenv commit SHA — bump it when adopting newer prenv changes.

## Step 5: Write the Terraform stub

Copy `templates/main.tf`, `templates/variables.tf`, `templates/versions.tf`,
`templates/outputs.tf`, `templates/provider.tf` to `terraform/env/preview/`. Edit
`main.tf`'s `containers` list to describe this repo's application — see
`terraform/modules/preview/README.md` in prenv for the schema and validation
rules (exactly one container needs `port`; every `depends_on` target needs a
`startup_probe`). The template sets `enable_db_sidecar = false`; flip it to
`true` only if the app needs the built-in Postgres sidecar.

## Manual steps not covered

None. The project owner has already handled IAP OAuth bootstrap and the base apply.
