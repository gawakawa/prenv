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

variable "iap_service_agent_email" {
  description = "IAP service agent email (service-PROJECT_NUMBER@gcp-sa-iap.iam.gserviceaccount.com). Set from foundation output iap_service_agent_email."
  type        = string
}
