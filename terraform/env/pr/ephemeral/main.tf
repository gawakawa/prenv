data "google_project" "this" {
  project_id = var.project_id
}

resource "google_cloud_run_v2_service" "preview" {
  name     = "prenv-pr-${var.pr_number}"
  project  = var.project_id
  location = var.region

  # Must be false so `tofu destroy` can remove the service on PR close.
  deletion_protection = false

  # Enable IAP — restricts access to identities listed in the foundation's
  # iap_members variable. Public (allUsers) access is removed.
  iap_enabled = true

  template {
    containers {
      image = var.image
    }
  }
}

# Grant the IAP service agent permission to invoke the Cloud Run service.
# End users do not call the service directly; IAP proxies the request on
# their behalf after verifying identity via OAuth.
resource "google_cloud_run_v2_service_iam_member" "invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.preview.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-iap.iam.gserviceaccount.com"
}
