terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # Phase 1: keep commented out, run `tofu init` with local backend.
  # Phase 2: after first apply creates the bucket, uncomment and run `tofu init -migrate-state`.
  #
  # backend "gcs" {
  #   bucket = "REPLACE_WITH_state_bucket_name"
  #   prefix = "bootstrap"
  # }
}
