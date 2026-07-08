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

variable "backend_image" {
  description = "Backend container image to deploy. Defaults to a public placeholder (for teardown); replace with the built backend image for deploy."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "db_image" {
  description = "Database (postgres) container image to deploy. Defaults to a public placeholder (for teardown); replace with the built db image for deploy."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "frontend_image" {
  description = "Frontend container image to deploy. Defaults to a public placeholder (for teardown); replace with the built frontend image for deploy."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}
