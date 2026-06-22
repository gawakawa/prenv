# Grant IAP access to preview environments at the PROJECT level.
#
# Project-level binding covers every Cloud Run service in the project, so no
# extra IAP permissions are needed on the CI deploy SA — the deployer's
# existing roles/run.admin is sufficient to set iap_enabled and grant the IAP
# service agent run.invoker.
#
# Per-service binding (google_iap_web_cloud_run_service_iam_member) is
# intentionally avoided: it would require the CI SA to hold roles/iap.admin,
# and that resource has a known provider bug (hashicorp/terraform-provider-google#23092).
resource "google_iap_web_iam_member" "preview_accessor" {
  for_each = toset(var.iap_members)

  project = var.project_id
  role    = "roles/iap.httpsResourceAccessor"
  member  = each.value

  depends_on = [google_project_service.core]
}
