terraform {
  required_version = ">= 1.9.0"

  required_providers {
    # iap_enabled on google_cloud_run_v2_service is a Beta-only field.
    # >= 7.15 fixes a scaling-block permadiff (magic-modules #15808, #15904).
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.15"
    }
  }
}
