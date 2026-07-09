# IAP custom OAuth client credentials, stored in Secret Manager.
#
# Projects outside a Google Cloud organization cannot use Google-managed OAuth
# for IAP, so a custom OAuth client must be created manually in the Console.
# Only the containers are managed here — values are loaded out-of-band
# (gcloud/Console), so apply only ever needs IAM access to Secret Manager,
# never the client secret's raw value, and the value never passes through a
# Terraform variable or gets written to state.
#
# google_iap_settings does not expose client_id/client_secret, and
# google_iap_brand/google_iap_client require an organization, so the IAP
# binding itself stays manual.
#
# The secretmanager.googleapis.com API is enabled via google_project_service.core in this module.
resource "google_secret_manager_secret" "iap_oauth_client_id" {
  secret_id = "iap-oauth-client-id"
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "iap_oauth_client_secret" {
  secret_id = "iap-oauth-client-secret"
  project   = var.project_id

  replication {
    auto {}
  }
}
