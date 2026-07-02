# Grant IAP access to preview environments at the PROJECT level, covering
# every Cloud Run service without needing IAP permissions on the CI deploy SA.
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

data "google_project" "this" {
  project_id = var.project_id
}

# Grant the IAP service agent run.invoker at the PROJECT level. Applied once
# here instead of per-service on each deploy, so CI never touches Cloud Run
# IAM and there's no post-deploy propagation delay causing a transient 403.
resource "google_project_iam_member" "iap_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-iap.iam.gserviceaccount.com"

  depends_on = [google_project_service.core]
}
