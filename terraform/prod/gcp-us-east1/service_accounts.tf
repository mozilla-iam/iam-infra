# Service accounts for deployments.

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
