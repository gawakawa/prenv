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

variable "image_max_age" {
  description = "Delete preview images older than this age. Must exceed the stale-sweep window (3 days) so in-use images are never removed."
  type        = string
  default     = "604800s" # 7 days
}

variable "image_cleanup_dry_run" {
  description = "When true, the cleanup policy only logs what it would delete instead of deleting. Set to true first to inspect matches before enabling deletion."
  type        = bool
  default     = false
}

variable "state_bucket_name" {
  description = "Globally-unique GCS bucket name for Terraform state. Recommend prefixing with project_id (e.g. my-project-tfstate)."
  type        = string
}

variable "github_repositories" {
  description = "GitHub repositories in OWNER/REPO format (e.g. [\"my-org/app-a\", \"my-org/app-b\"]) allowed to impersonate the deploy SA via WIF."
  type        = list(string)

  validation {
    condition     = length(var.github_repositories) > 0
    error_message = "github_repositories must not be empty."
  }

  validation {
    condition     = alltrue([for r in var.github_repositories : can(regex("^[^/]+/[^/]+$", r))])
    error_message = "Each entry must be in OWNER/REPO form."
  }
}

variable "iap_members" {
  description = "Members granted IAP access to all preview environments (e.g. [\"user:you@example.com\"]). Uses project-level binding so no IAP permissions are needed on the CI deploy SA."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.iap_members) > 0
    error_message = "iap_members must not be empty — at least one member must be granted access, otherwise all preview environments will return IAP 403."
  }
}
