variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "Region for the Cloud Run service."
  type        = string
  default     = "asia-northeast1"
}

variable "pr_number" {
  description = "Pull request number. Used to name and isolate the preview environment."
  type        = number
}

variable "repo" {
  description = "GitHub repository in OWNER/REPO format. Disambiguates the Cloud Run service name when multiple repositories share this managed project."
  type        = string
}

variable "image" {
  description = "Container image to deploy. Defaults to a public placeholder; replace with your app image."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "db_image" {
  description = "Postgres sidecar image with migration and seed SQL baked in via initdb. Defaults to vanilla postgres:18-alpine (for teardown); replace with the built db image for deploy."
  type        = string
  default     = "postgres:18-alpine"
}

variable "frontend_image" {
  description = "Frontend container image to deploy. Defaults to a public placeholder (for teardown); replace with the built frontend image for deploy."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}
