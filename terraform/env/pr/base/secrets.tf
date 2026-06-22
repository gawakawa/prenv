# IAP custom OAuth client credentials, stored in Secret Manager.
#
# Projects outside a Google Cloud organization cannot use Google-managed OAuth
# for IAP, so a custom OAuth client must be created manually in the Console.
# Its credentials are stored here as the source of truth and bound to IAP via
# the one-time `gcloud iap settings set` bootstrap documented in the README.
#
# google_iap_settings does not expose client_id/client_secret, and
# google_iap_brand/google_iap_client require an organization, so the IAP
# binding itself stays manual.
#
# The secretmanager.googleapis.com API is enabled in terraform/shared.
resource "google_secret_manager_secret" "iap_oauth_client_id" {
  secret_id = "iap-oauth-client-id"
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "iap_oauth_client_id" {
  secret      = google_secret_manager_secret.iap_oauth_client_id.id
  secret_data = var.iap_oauth_client_id
}

resource "google_secret_manager_secret" "iap_oauth_client_secret" {
  secret_id = "iap-oauth-client-secret"
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "iap_oauth_client_secret" {
  secret      = google_secret_manager_secret.iap_oauth_client_secret.id
  secret_data = var.iap_oauth_client_secret
}
