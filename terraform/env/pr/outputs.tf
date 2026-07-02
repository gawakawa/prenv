output "url" {
  description = "HTTPS URL of the preview Cloud Run service."
  value       = google_cloud_run_v2_service.preview.uri
}
