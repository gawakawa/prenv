output "repository_url" {
  description = "Docker registry URL for this Artifact Registry repository. Set as GitHub Actions variable AR_REPO."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.preview.repository_id}"
}
