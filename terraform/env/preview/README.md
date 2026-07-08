# terraform/env/preview

Per-PR preview environment. Deploys one Cloud Run service (`<owner>-<repo>-pr-<N>`) per PR and
protects it behind Identity-Aware Proxy (IAP); only members granted IAP access can reach its
`.run.app` URL.

Applied and destroyed automatically by GitHub Actions on PR label / PR close.
Not applied manually.

## State isolation

Each PR gets its own Terraform state prefix: `<owner>/<repo>/pr/<N>` in the shared GCS
bucket. The `<owner>/<repo>` segment keeps PRs from colliding when multiple repositories
share the same managed project (see `docs/DESIGN.md`). The prefix is passed at init
time — not hardcoded here:

```bash
tofu init -backend-config="bucket=my-project-tfstate" -backend-config="prefix=my-org/my-repo/pr/123"
tofu apply -var="project_id=my-project" -var="pr_number=123" -var="repo=my-org/my-repo"
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 6.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | ~> 7.15 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_preview"></a> [preview](#module\_preview) | ../../modules/preview | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_pr_number"></a> [pr\_number](#input\_pr\_number) | Pull request number. Used to name and isolate the preview environment. | `number` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Google Cloud project ID. | `string` | n/a | yes |
| <a name="input_repo"></a> [repo](#input\_repo) | GitHub repository in OWNER/REPO format. Disambiguates the Cloud Run service name when multiple repositories share this managed project. | `string` | n/a | yes |
| <a name="input_tfstate_bucket"></a> [tfstate\_bucket](#input\_tfstate\_bucket) | GCS bucket holding per-PR Terraform state. Read by the backend container to discover PR numbers for previews that have been torn down. | `string` | n/a | yes |
| <a name="input_images"></a> [images](#input\_images) | Map of image name (backend, db, frontend) to fully-qualified image reference, built and passed in by CI. Empty on teardown, where no build happens and placeholder defaults apply. | `map(string)` | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for the Cloud Run service. | `string` | `"asia-northeast1"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_url"></a> [url](#output\_url) | HTTPS URL of the preview Cloud Run service. |
<!-- END_TF_DOCS -->
