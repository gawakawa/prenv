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
