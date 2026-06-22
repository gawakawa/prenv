# terraform/env/pr/ephemeral

Per-PR preview environment. Deploys one Cloud Run service (`prenv-pr-<N>`) per PR and makes it
publicly accessible via its `.run.app` URL.

Applied and destroyed automatically by GitHub Actions on PR label / PR close.
Not applied manually.

## State isolation

Each PR gets its own Terraform state prefix: `pr/<N>` in the shared GCS bucket.
The prefix is passed at init time — not hardcoded here — so PRs never share state:

```bash
tofu init -backend-config="bucket=my-project-tfstate" -backend-config="prefix=pr/123"
tofu apply -var="project_id=my-project" -var="pr_number=123"
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 6.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | ~> 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | 6.50.0 |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | 6.50.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google-beta_google_cloud_run_v2_service.preview](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_cloud_run_v2_service) | resource |
| [google_cloud_run_v2_service_iam_member.invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service_iam_member) | resource |
| [google_project.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_pr_number"></a> [pr\_number](#input\_pr\_number) | Pull request number. Used to name and isolate the preview environment. | `number` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Google Cloud project ID. | `string` | n/a | yes |
| <a name="input_image"></a> [image](#input\_image) | Container image to deploy. Defaults to a public placeholder; replace with your app image. | `string` | `"us-docker.pkg.dev/cloudrun/container/hello"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for the Cloud Run service. | `string` | `"asia-northeast1"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_url"></a> [url](#output\_url) | HTTPS URL of the preview Cloud Run service. |
<!-- END_TF_DOCS -->
