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
