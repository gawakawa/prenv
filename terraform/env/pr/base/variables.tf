variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "Region for the Artifact Registry repository."
  type        = string
  default     = "asia-northeast1"
}

variable "repository_id" {
  description = "Artifact Registry repository ID. Used as the Docker image repository name."
  type        = string
  default     = "prenv-preview"
}

variable "iap_oauth_client_id" {
  description = "IAP custom OAuth client ID (created manually in Console). Stored in Secret Manager and bound to IAP via `gcloud iap settings set`."
  type        = string
}

variable "iap_oauth_client_secret" {
  description = "IAP custom OAuth client secret (created manually in Console)."
  type        = string
  sensitive   = true
}
