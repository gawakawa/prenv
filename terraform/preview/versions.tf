terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # prefix is NOT set here — it is supplied at init time via:
  #   tofu init -backend-config="prefix=pr/<PR_NUMBER>"
  # Variable interpolation is not supported in backend blocks.
  backend "gcs" {
    bucket = "gawakawa-prenv-tfstate"
  }
}
