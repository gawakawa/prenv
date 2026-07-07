terraform {
  required_version = ">= 1.9.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    # iap_enabled on google_cloud_run_v2_service is a Beta-only field.
    # >= 7.15 fixes a scaling-block permadiff (magic-modules #15808, #15904).
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.15"
    }
  }

  # Neither bucket nor prefix is hardcoded here; both are supplied at init time:
  #   tofu init -backend-config="bucket=<state_bucket_name>" \
  #             -backend-config="prefix=pr/<PR_NUMBER>"
  # Variable interpolation is not supported in backend blocks.
  # bucket must match var.state_bucket_name in terraform/base.
  # Shared PR preview resources (Artifact Registry repo) live in terraform/base/.
  backend "gcs" {}
}
