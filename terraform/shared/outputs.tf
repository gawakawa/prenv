output "state_bucket_name" {
  description = "GCS bucket for Terraform state. Use as backend `bucket` in per-PR module."
  value       = google_storage_bucket.tfstate.name
}

output "wif_provider_name" {
  description = "Workload Identity Provider resource name. Set as GitHub Actions variable WIF_PROVIDER."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "deploy_service_account_email" {
  description = "Deploy service account email. Set as GitHub Actions variable DEPLOY_SA."
  value       = google_service_account.deployer.email
}

output "iap_service_agent_email" {
  description = "IAP service agent email. Set as GitHub Actions variable IAP_SERVICE_AGENT_EMAIL."
  value       = google_project_service_identity.iap.email
}
