# Service accounts for deployments.

# It's this account that GitHub uses. See the policies in GCP for the full
# picture.
resource "google_service_account" "sso_dashboard" {
  account_id                   = "sso-dashboard"
  display_name                 = "sso-dashboard"
}

resource "google_service_account" "sso_dashboard_staging" {
  account_id                   = "sso-dashboard-staging"
  description                  = "A dedicated service account for sso-dashboard-staging cloud run serivce"
  display_name                 = "sso-dashboard-staging"
}

resource "google_service_account" "sso_dashboard_prod" {
  account_id                   = "sso-dashboard-prod"
  description                  = "A dedicated service account for sso-dashboard-prod cloud run serivce "
  display_name                 = "sso-dashboard-prod"
}

resource "google_service_account" "runtime_sso_dashboard_dev" {
  account_id                   = "sso-dashboard-dev-runtime"
  display_name                 = "SSO Dashboard Dev (runtime)"
}

resource "google_secret_manager_secret_iam_member" "runtime_sso_dashboard_dev_secret_key" {
  secret_id = data.google_secret_manager_secret.sso_dashboard_dev_secret_key.secret_id
  role = "roles/secretmanager.secretAccessor"
  member = google_service_account.runtime_sso_dashboard_dev.member
}

resource "google_secret_manager_secret_iam_member" "runtime_sso_dashboard_dev_oidc_client_secret" {
  secret_id = data.google_secret_manager_secret.sso_dashboard_dev_oidc_client_secret.secret_id
  role = "roles/secretmanager.secretAccessor"
  member = google_service_account.runtime_sso_dashboard_dev.member
}

resource "google_service_account" "runtime_sso_dashboard_stage" {
  account_id                   = "sso-dashboard-stage-runtime"
  display_name                 = "SSO Dashboard Stage (runtime)"
}

resource "google_secret_manager_secret_iam_member" "runtime_sso_dashboard_stage_secret_key" {
  secret_id = data.google_secret_manager_secret.sso_dashboard_prod_secret_key.secret_id
  role = "roles/secretmanager.secretAccessor"
  member = google_service_account.runtime_sso_dashboard_stage.member
}

resource "google_secret_manager_secret_iam_member" "runtime_sso_dashboard_stage_oidc_client_secret" {
  secret_id = data.google_secret_manager_secret.sso_dashboard_prod_oidc_client_secret.secret_id
  role = "roles/secretmanager.secretAccessor"
  member = google_service_account.runtime_sso_dashboard_stage.member
}

resource "google_service_account" "runtime_sso_dashboard_prod" {
  account_id                   = "sso-dashboard-prod-runtime"
  display_name                 = "SSO Dashboard Prod (runtime)"
}

resource "google_secret_manager_secret_iam_member" "runtime_sso_dashboard_prod_secret_key" {
  secret_id = data.google_secret_manager_secret.sso_dashboard_prod_secret_key.secret_id
  role = "roles/secretmanager.secretAccessor"
  member = google_service_account.runtime_sso_dashboard_prod.member
}

resource "google_secret_manager_secret_iam_member" "runtime_sso_dashboard_prod_oidc_client_secret" {
  secret_id = data.google_secret_manager_secret.sso_dashboard_prod_oidc_client_secret.secret_id
  role = "roles/secretmanager.secretAccessor"
  member = google_service_account.runtime_sso_dashboard_prod.member
}
