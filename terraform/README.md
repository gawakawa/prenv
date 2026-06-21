# terraform

Shared foundation resources that must exist before any per-PR environment is provisioned.

## What this creates

- Required Google Cloud APIs enabled
- GCS bucket for Terraform state (used by this module and per-PR modules)

## Usage

Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values (already gitignored).

### Phase 1 — initial apply (local backend)

`backend "gcs"` in `versions.tf` must stay commented out for the first apply, because the state bucket doesn't exist yet.

```bash
cd terraform
tofu init
tofu apply -var-file=terraform.tfvars
```

### Phase 2 — migrate state to GCS

Uncomment the `backend "gcs"` block in `versions.tf` and set `bucket` to the literal bucket name you just created (variable interpolation is not supported in backend blocks). Then:

```bash
tofu init -migrate-state
```

Confirm the migration when prompted, then delete the local `terraform.tfstate`.

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
