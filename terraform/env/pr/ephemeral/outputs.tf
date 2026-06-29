output "url" {
  description = "HTTPS URL of the frontend preview Cloud Run service."
  value       = google_cloud_run_v2_service.frontend.uri
}

output "backend_url" {
  description = "HTTPS URL of the backend preview Cloud Run service."
  value       = google_cloud_run_v2_service.preview.uri
}
