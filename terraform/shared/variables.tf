variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "Default region."
  type        = string
  default     = "asia-northeast1"
}

variable "state_bucket_name" {
  description = "Globally-unique GCS bucket name for Terraform state. Recommend prefixing with project_id (e.g. my-project-tfstate)."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in OWNER/REPO format (e.g. gawakawa/prenv). Restricts WIF to this repo only."
  type        = string
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
