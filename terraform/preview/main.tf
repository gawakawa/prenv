resource "google_cloud_run_v2_service" "preview" {
  name     = "prenv-pr-${var.pr_number}"
  project  = var.project_id
  location = var.region

  # Must be false so `tofu destroy` can remove the service on PR close.
  deletion_protection = false

  template {
    containers {
      image = var.image
    }
  }
}

# Make the preview URL publicly accessible.
# Note: this can be blocked by an org policy (iam.allowedPolicyMemberDomains).
# If apply fails with a policy violation, relax the constraint for this project.
resource "google_cloud_run_v2_service_iam_member" "invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.preview.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
