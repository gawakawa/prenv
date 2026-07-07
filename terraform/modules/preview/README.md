# terraform/modules/preview

Reusable Cloud Run preview environment. Deploys one multi-container service
(`prenv-pr-<N>`) protected by Identity-Aware Proxy (IAP); only members granted
IAP access can reach its `.run.app` URL.

Callers supply their own application containers via `containers`; the module
always owns naming, `launch_stage`, IAP, and (when `enable_db_sidecar = true`)
a Postgres sidecar. See `terraform/env/pr` for a calling example.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | ~> 7.15 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | 7.39.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google-beta_google_cloud_run_v2_service.preview](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_cloud_run_v2_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_containers"></a> [containers](#input\_containers) | Application containers to run inside the preview service. Exactly one<br/>container must set `port` (Cloud Run ingress). Every name listed in<br/>another container's `depends_on` must belong to a container with a<br/>`startup_probe` — Cloud Run rejects the deploy with a 400 otherwise —<br/>or (when `enable_db_sidecar = true`) be the built-in `postgres` sidecar.<br/><br/>When `enable_db_sidecar = true`, a Postgres container named `postgres`<br/>listens on `localhost:5432` with database `app`, user `postgres`, and no<br/>password. Wire it explicitly on the container that needs it:<br/>  env        = [{ name = "DATABASE\_URL", value = "postgres://postgres@localhost:5432/app?sslmode=disable" }]<br/>  depends\_on = ["postgres"] | <pre>list(object({<br/>    name              = string<br/>    image             = string<br/>    port              = optional(number)<br/>    env               = optional(list(object({ name = string, value = string })), [])<br/>    depends_on        = optional(list(string), [])<br/>    cpu_limit         = optional(string, "1")<br/>    memory_limit      = optional(string, "512Mi")<br/>    startup_cpu_boost = optional(bool, true)<br/>    startup_probe = optional(object({<br/>      tcp_port              = number<br/>      initial_delay_seconds = optional(number, 5)<br/>      period_seconds        = optional(number, 5)<br/>      timeout_seconds       = optional(number, 3)<br/>      failure_threshold     = optional(number, 24)<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_pr_number"></a> [pr\_number](#input\_pr\_number) | Pull request number. Used to name and isolate the preview environment. | `number` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Google Cloud project ID. | `string` | n/a | yes |
| <a name="input_db_image"></a> [db\_image](#input\_db\_image) | Postgres sidecar image. Ignored when enable\_db\_sidecar = false. | `string` | `"postgres:18-alpine"` | no |
| <a name="input_enable_db_sidecar"></a> [enable\_db\_sidecar](#input\_enable\_db\_sidecar) | Run a Postgres sidecar container (name `postgres`, localhost:5432, database `app`) alongside the application containers. | `bool` | `true` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for the Cloud Run service. | `string` | `"asia-northeast1"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_url"></a> [url](#output\_url) | HTTPS URL of the preview Cloud Run service. |
<!-- END_TF_DOCS -->
