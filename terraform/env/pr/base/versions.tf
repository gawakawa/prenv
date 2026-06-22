terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # State is stored in the shared GCS bucket under prefix "env/pr/base".
  # This module is applied once manually (not by CI).
  # bucket must match var.state_bucket_name (managed in this module).
  backend "gcs" {
    bucket = "gawakawa-prenv-tfstate"
    prefix = "env/pr/base"
  }
}
