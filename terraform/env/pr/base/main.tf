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
