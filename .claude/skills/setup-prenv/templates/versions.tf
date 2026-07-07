terraform {
  required_version = ">= 1.9.0"

  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.15"
    }
  }

  # Neither bucket nor prefix is hardcoded here; both are supplied at init time:
  #   tofu init -backend-config="bucket=<state_bucket_name>" \
  #             -backend-config="prefix=<owner>/<repo>/pr/<PR_NUMBER>"
  # bucket must match the managed project's terraform/base state_bucket_name output.
  backend "gcs" {}
}
