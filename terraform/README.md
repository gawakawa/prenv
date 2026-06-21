# terraform

Shared foundation resources that must exist before any per-PR environment is provisioned.

## What this creates

- Required Google Cloud APIs enabled
- GCS bucket for Terraform state (used by this module and per-PR modules)

## Usage

The GCS backend is already configured and committed in `versions.tf`, so state lives in `gs://gawakawa-prenv-tfstate` (prefix `bootstrap`). Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values (already gitignored), then:

```bash
cd terraform
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
| [google_project_service.core](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_storage_bucket.tfstate](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Google Cloud project ID. | `string` | n/a | yes |
| <a name="input_state_bucket_name"></a> [state\_bucket\_name](#input\_state\_bucket\_name) | Globally-unique GCS bucket name for Terraform state. Recommend prefixing with project\_id (e.g. my-project-tfstate). | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Default region. | `string` | `"asia-northeast1"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_state_bucket_name"></a> [state\_bucket\_name](#output\_state\_bucket\_name) | GCS bucket for Terraform state. Use as backend `bucket` in per-PR module. |
<!-- END_TF_DOCS -->
