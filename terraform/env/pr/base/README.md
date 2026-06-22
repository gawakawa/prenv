# terraform/env/pr/base

Shared resources for PR preview environments. Applied once manually — not per-PR.

## What this creates

- Artifact Registry repository (`DOCKER` format) for preview environment container images

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
| [google_secret_manager_secret.iap_oauth_client_id](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret.iap_oauth_client_secret](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_version.iap_oauth_client_id](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_secret_manager_secret_version.iap_oauth_client_secret](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_iap_oauth_client_id"></a> [iap\_oauth\_client\_id](#input\_iap\_oauth\_client\_id) | IAP custom OAuth client ID (created manually in Console). Stored in Secret Manager and bound to IAP via `gcloud iap settings set`. | `string` | n/a | yes |
| <a name="input_iap_oauth_client_secret"></a> [iap\_oauth\_client\_secret](#input\_iap\_oauth\_client\_secret) | IAP custom OAuth client secret (created manually in Console). | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Google Cloud project ID. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region for the Artifact Registry repository. | `string` | `"asia-northeast1"` | no |
| <a name="input_repository_id"></a> [repository\_id](#input\_repository\_id) | Artifact Registry repository ID. Used as the Docker image repository name. | `string` | `"prenv-preview"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_repository_url"></a> [repository\_url](#output\_repository\_url) | Docker registry URL for this Artifact Registry repository. Set as GitHub Actions variable AR\_REPO. |
<!-- END_TF_DOCS -->
