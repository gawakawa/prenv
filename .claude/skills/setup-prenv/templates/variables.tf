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

variable "images" {
  description = "Map of image name to fully-qualified image reference, built and passed in by CI. Empty on teardown, where no build happens and the placeholder default applies."
  type        = map(string)
  default     = {}
}
