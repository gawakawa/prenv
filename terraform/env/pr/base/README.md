# terraform/env/pr/base

Shared resources for PR preview environments. Applied once manually — not per-PR.

## What this creates

- Artifact Registry repository (`DOCKER` format) for preview environment container images, with a cleanup policy that deletes images older than `image_max_age` (default: 7 days)

## Usage

```bash
cd terraform/env/pr/base
# region and repository_id have defaults; only project_id is required
tofu init
tofu apply -var project_id=<your-project-id>
```

After applying, register the output as a GitHub Actions repository variable:

| Variable | Value |
|---|---|
| `AR_REPO` | `tofu output -raw repository_url` |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | 6.50.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_artifact_registry_repository.preview](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository) | resource |
| [google_artifact_registry_repository_iam_member.cloudbuild_ar_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam_member) | resource |
| [google_artifact_registry_repository_iam_member.deployer_ar_reader](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam_member) | resource |
| [google_iam_workload_identity_pool.github](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool) | resource |
| [google_iam_workload_identity_pool_provider.github](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider) | resource |
| [google_iap_web_iam_member.preview_accessor](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iap_web_iam_member) | resource |
| [google_project_iam_member.cloudbuild_log_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.deployer_cloudbuild_editor](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.deployer_run_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.deployer_sa_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.deployer_serviceusage](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.iap_run_invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.core](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_secret_manager_secret.iap_oauth_client_id](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret.iap_oauth_client_secret](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_version.iap_oauth_client_id](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_secret_manager_secret_version.iap_oauth_client_secret](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_service_account.cloudbuild](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account.deployer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.deployer_actAs_cloudbuild](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_service_account_iam_member.wif_deployer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_storage_bucket.cloudbuild](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket.tfstate](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_iam_member.deployer_cloudbuild_staging](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_storage_bucket_iam_member.deployer_tfstate](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_project.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_github_repository"></a> [github\_repository](#input\_github\_repository) | GitHub repository in OWNER/REPO format (e.g. gawakawa/prenv). Restricts WIF to this repo only. | `string` | n/a | yes |
| <a name="input_iap_oauth_client_id"></a> [iap\_oauth\_client\_id](#input\_iap\_oauth\_client\_id) | IAP custom OAuth client ID (created manually in Console). Stored in Secret Manager and bound to IAP via `gcloud iap settings set`. | `string` | n/a | yes |
| <a name="input_iap_oauth_client_secret"></a> [iap\_oauth\_client\_secret](#input\_iap\_oauth\_client\_secret) | IAP custom OAuth client secret (created manually in Console). | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Google Cloud project ID. | `string` | n/a | yes |
| <a name="input_state_bucket_name"></a> [state\_bucket\_name](#input\_state\_bucket\_name) | Globally-unique GCS bucket name for Terraform state. Recommend prefixing with project\_id (e.g. my-project-tfstate). | `string` | n/a | yes |
| <a name="input_iap_members"></a> [iap\_members](#input\_iap\_members) | Members granted IAP access to all preview environments (e.g. ["user:you@example.com"]). Uses project-level binding so no IAP permissions are needed on the CI deploy SA. | `list(string)` | `[]` | no |
| <a name="input_image_cleanup_dry_run"></a> [image\_cleanup\_dry\_run](#input\_image\_cleanup\_dry\_run) | When true, the cleanup policy only logs what it would delete instead of deleting. Set to true first to inspect matches before enabling deletion. | `bool` | `false` | no |
| <a name="input_image_max_age"></a> [image\_max\_age](#input\_image\_max\_age) | Delete preview images older than this age. Must exceed the stale-sweep window (3 days) so in-use images are never removed. | `string` | `"604800s"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for the Artifact Registry repository. | `string` | `"asia-northeast1"` | no |
| <a name="input_repository_id"></a> [repository\_id](#input\_repository\_id) | Artifact Registry repository ID. Used as the Docker image repository name. | `string` | `"prenv-preview"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_build_service_account_email"></a> [build\_service\_account\_email](#output\_build\_service\_account\_email) | Cloud Build service account email. Set as the `pr` environment variable BUILD\_SA. |
| <a name="output_deploy_service_account_email"></a> [deploy\_service\_account\_email](#output\_deploy\_service\_account\_email) | Deploy service account email. Set as the `pr` environment variable DEPLOY\_SA. |
| <a name="output_repository_url"></a> [repository\_url](#output\_repository\_url) | Docker registry URL for this Artifact Registry repository. Set as GitHub Actions variable AR\_REPO. |
| <a name="output_state_bucket_name"></a> [state\_bucket\_name](#output\_state\_bucket\_name) | GCS bucket for Terraform state. Use as backend `bucket` in per-PR module. |
| <a name="output_wif_provider_name"></a> [wif\_provider\_name](#output\_wif\_provider\_name) | Workload Identity Provider resource name. Set as the `pr` environment variable WIF\_PROVIDER. |
<!-- END_TF_DOCS -->
