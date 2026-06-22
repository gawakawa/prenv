resource "google_artifact_registry_repository" "preview" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = "Docker images for per-PR preview environments."
}
