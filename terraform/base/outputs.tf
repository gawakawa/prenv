output "project_id" {
  description = "Google Cloud project ID. Set as the `preview` environment variable GCP_PROJECT_ID."
  value       = var.project_id
}

output "repository_url" {
  description = "Docker registry URL for this Artifact Registry repository. Set as GitHub Actions variable AR_REPO."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.preview.repository_id}"
}

output "state_bucket_name" {
  description = "GCS bucket for Terraform state. Use as backend `bucket` in per-PR module."
  value       = google_storage_bucket.tfstate.name
}

output "wif_provider_name" {
  description = "Workload Identity Provider resource name. Set as the `preview` environment variable WIF_PROVIDER."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "deploy_service_account_email" {
  description = "Deploy service account email. Set as the `preview` environment variable DEPLOY_SA."
  value       = google_service_account.deployer.email
}

output "build_service_account_email" {
  description = "Cloud Build service account email. Set as the `preview` environment variable BUILD_SA."
  value       = google_service_account.cloudbuild.email
}
