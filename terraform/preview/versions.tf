terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # Neither bucket nor prefix is hardcoded here; both are supplied at init time:
  #   tofu init -backend-config="bucket=<state_bucket_name>" \
  #             -backend-config="prefix=pr/<PR_NUMBER>"
  # Variable interpolation is not supported in backend blocks.
  # bucket must match var.state_bucket_name in the foundation (terraform/).
  backend "gcs" {}
}
