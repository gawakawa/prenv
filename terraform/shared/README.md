# terraform/shared

Shared foundation resources that must exist before any per-PR environment is provisioned.

## What this creates

- Required Google Cloud APIs enabled (including IAM Credentials and STS for WIF)
- GCS bucket for Terraform state (used by this module and per-PR modules)
- Workload Identity Federation pool + provider for GitHub Actions OIDC
- `prenv-deployer` service account with permissions to manage Cloud Run preview environments
- IAM binding scoped to `var.github_repository` — only that repo can impersonate the SA

## Usage

The GCS backend is already configured and committed in `versions.tf`, so state lives in `gs://gawakawa-prenv-tfstate` (prefix `bootstrap`). Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values (already gitignored), then:

```bash
cd terraform/shared
tofu init
tofu apply -var-file=terraform.tfvars
```

## Re-bootstrapping from scratch

Only needed when the state bucket does not yet exist (a brand-new project). The bucket can't be created while the backend points at it, so bootstrap in two phases:

1. Comment out the `backend "gcs"` block in `versions.tf`, then `tofu init` (local backend) and `tofu apply -var-file=terraform.tfvars` to create the bucket.
2. Uncomment the `backend "gcs"` block and set `bucket` to the literal bucket name just created (variable interpolation is not supported in backend blocks), then `tofu init -migrate-state`. Confirm the migration, then delete the local `terraform.tfstate`.

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
| [google_iam_workload_identity_pool.github](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool) | resource |
| [google_iam_workload_identity_pool_provider.github](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider) | resource |
| [google_iap_web_iam_member.preview_accessor](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iap_web_iam_member) | resource |
| [google_project_iam_member.deployer_ar_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.deployer_run_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.deployer_sa_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.core](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service_identity.iap](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service_identity) | resource |
| [google_service_account.deployer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.wif_deployer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_storage_bucket.tfstate](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_iam_member.deployer_tfstate](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_github_repository"></a> [github\_repository](#input\_github\_repository) | GitHub repository in OWNER/REPO format (e.g. gawakawa/prenv). Restricts WIF to this repo only. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Google Cloud project ID. | `string` | n/a | yes |
| <a name="input_state_bucket_name"></a> [state\_bucket\_name](#input\_state\_bucket\_name) | Globally-unique GCS bucket name for Terraform state. Recommend prefixing with project\_id (e.g. my-project-tfstate). | `string` | n/a | yes |
| <a name="input_iap_members"></a> [iap\_members](#input\_iap\_members) | Members granted IAP access to all preview environments (e.g. ["user:you@example.com"]). Uses project-level binding so no IAP permissions are needed on the CI deploy SA. | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | Default region. | `string` | `"asia-northeast1"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_deploy_service_account_email"></a> [deploy\_service\_account\_email](#output\_deploy\_service\_account\_email) | Deploy service account email. Set as the `pr` environment variable DEPLOY\_SA. |
| <a name="output_state_bucket_name"></a> [state\_bucket\_name](#output\_state\_bucket\_name) | GCS bucket for Terraform state. Use as backend `bucket` in per-PR module. |
| <a name="output_wif_provider_name"></a> [wif\_provider\_name](#output\_wif\_provider\_name) | Workload Identity Provider resource name. Set as the `pr` environment variable WIF\_PROVIDER. |
<!-- END_TF_DOCS -->
