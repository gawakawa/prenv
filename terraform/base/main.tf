locals {
  services = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "storage.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "iap.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudbuild.googleapis.com",
  ]
}

resource "google_project_service" "core" {
  for_each = toset(local.services)

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_storage_bucket" "tfstate" {
  name     = var.state_bucket_name
  project  = var.project_id
  location = var.region

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 10
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.core]
}

# Cloud Run's default runtime identity reads tfstate objects to discover PR
# numbers for previews that have been torn down (see
# backend/monitoring.go's listPrenvsFromTfstate, which calls Objects() — a
# storage.objects.list operation). This identity is shared by every onboarded
# repository's preview services, so ideally this grant would be restricted to
# each repository's own tfstate prefix. That isn't possible here: GCS
# evaluates storage.objects.list at the bucket level, so a resource.name
# condition never matches and silently denies the whole list operation
# (Google's own IAM conditions docs: "you cannot use the resource.name
# condition attribute to restrict object listing access to a subset of
# objects in the bucket"). The role is kept to read-only (objectViewer) as
# the only available scoping.
resource "google_storage_bucket_iam_member" "cloudrun_runtime_tfstate_reader" {
  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${data.google_project.this.number}-compute@developer.gserviceaccount.com"
}

# Cloud Run's default runtime identity also calls ListServices (see
# backend/monitoring.go's listRunningPrenvs) to discover currently running
# previews. Granted explicitly rather than relying on the legacy Editor role
# some projects auto-grant to this service account. This is app-level
# permission, which normally belongs in env/preview, but this identity is
# shared project-wide — granting it per-PR would let any single PR's destroy
# revoke it for every other running preview.
resource "google_project_iam_member" "cloudrun_runtime_run_viewer" {
  project = var.project_id
  role    = "roles/run.viewer"
  member  = "serviceAccount:${data.google_project.this.number}-compute@developer.gserviceaccount.com"
}

resource "google_artifact_registry_repository" "preview" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = "Docker images for per-PR preview environments."

  # Server-side GC: delete stale preview images automatically.
  # The daily stale sweep (preview-teardown.yml) destroys Cloud Run services after 3 days,
  # so images older than that threshold are safe to delete — in-use images are always newer.
  cleanup_policy_dry_run = var.image_cleanup_dry_run

  cleanup_policies {
    id     = "delete-stale-preview-images"
    action = "DELETE"
    condition {
      older_than = var.image_max_age
    }
  }

  depends_on = [google_project_service.core]
}

resource "google_storage_bucket" "cloudbuild" {
  name     = "${var.project_id}_cloudbuild"
  project  = var.project_id
  location = var.region

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  depends_on = [google_project_service.core]
}
