output "state_bucket_name" {
  description = "GCS bucket for Terraform state. Use as backend `bucket` in per-PR module."
  value       = google_storage_bucket.tfstate.name
}
