resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "prenv-github"
  project                   = var.project_id
  display_name              = "GitHub Actions – prenv"
  description               = "WIF pool for per-PR preview environment workflows."

  depends_on = [google_project_service.core]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions"
  project                            = var.project_id
  display_name                       = "GitHub Actions OIDC"
  description                        = "Allows GitHub Actions in the configured repositories to impersonate the deploy SA."

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.actor"      = "assertion.actor"
    "attribute.ref"        = "assertion.ref"
  }

  # Restrict to the configured repositories — prevents other repos from using this provider.
  attribute_condition = "assertion.repository in [${join(", ", formatlist("%q", var.github_repositories))}]"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "deployer" {
  account_id   = "prenv-deployer"
  project      = var.project_id
  display_name = "prenv deploy SA"
  description  = "Impersonated by GitHub Actions to manage per-PR Cloud Run preview environments."
}

# Allow the WIF pool (scoped to the configured repositories) to impersonate the deploy SA.
resource "google_service_account_iam_member" "wif_deployer" {
  for_each = toset(var.github_repositories)

  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${each.value}"
}

# Deploy SA needs to create/update/delete Cloud Run services, but not set their IAM —
# the IAP service agent's run.invoker is granted at the project level (see iap.tf).
resource "google_project_iam_member" "deployer_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.deployer.email}"
}

# Deploy SA needs actAs the default compute SA used as Cloud Run's runtime identity.
resource "google_project_iam_member" "deployer_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.deployer.email}"
}

# Deploy SA needs read/write access to per-PR Terraform state prefixes.
resource "google_storage_bucket_iam_member" "deployer_tfstate" {
  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.deployer.email}"
}


resource "google_project_iam_member" "deployer_cloudbuild_editor" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${google_service_account.deployer.email}"
}

# Deploy SA uploads source to the Cloud Build staging bucket. `gcloud builds
# submit --service-account=...` needs bucket-level roles/storage.admin here —
# roles/storage.objectAdmin alone fails with "forbidden from accessing the
# bucket" (a known gap: Google's own docs don't state a storage role for this
# path, but this is the role that resolves the error in practice).
resource "google_storage_bucket_iam_member" "deployer_cloudbuild_staging" {
  bucket = google_storage_bucket.cloudbuild.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.deployer.email}"
}

resource "google_artifact_registry_repository_iam_member" "deployer_ar_reader" {
  project    = var.project_id
  location   = google_artifact_registry_repository.preview.location
  repository = google_artifact_registry_repository.preview.repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.deployer.email}"
}

resource "google_project_iam_member" "deployer_serviceusage" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${google_service_account.deployer.email}"
}

resource "google_service_account" "cloudbuild" {
  account_id   = "prenv-cloudbuild"
  project      = var.project_id
  display_name = "prenv Cloud Build SA"
  description  = "Runs Cloud Build steps for per-PR preview image builds."
}

# Deploy SA must be able to act as the build SA when submitting builds.
resource "google_service_account_iam_member" "deployer_actAs_cloudbuild" {
  service_account_id = google_service_account.cloudbuild.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.deployer.email}"
}

resource "google_artifact_registry_repository_iam_member" "cloudbuild_ar_writer" {
  project    = var.project_id
  location   = google_artifact_registry_repository.preview.location
  repository = google_artifact_registry_repository.preview.repository_id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.cloudbuild.email}"
}

resource "google_project_iam_member" "cloudbuild_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}
