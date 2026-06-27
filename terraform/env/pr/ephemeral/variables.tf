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

variable "image" {
  description = "Container image to deploy. Defaults to a public placeholder; replace with your app image."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "db_image" {
  description = "Postgres sidecar image with migration and seed SQL baked in via initdb."
  type        = string
  default     = "postgres:18-alpine"
}
