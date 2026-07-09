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
  description = "Map of image name (backend, db, frontend) to fully-qualified image reference, built and passed in by CI. Empty on teardown, where no build happens and placeholder defaults apply."
  type        = map(string)
  default     = {}
}

variable "tfstate_bucket" {
  description = "GCS bucket holding per-PR Terraform state. Read by the backend container to discover PR numbers for previews that have been torn down."
  type        = string
}

variable "commit_sha" {
  description = "Full Git commit SHA deployed, passed in by CI. Empty on teardown, where no build happens. Exposed to the backend container so the dashboard can link to the exact commit — image tags are content-hashes, not commit SHAs."
  type        = string
  default     = ""
}
