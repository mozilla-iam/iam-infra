# SSO Dashboard

# There are no staging secrets. Staging and production share a client id, etc,
# etc.

# Bhee doesn't know why.

data "google_secret_manager_secret" "sso_dashboard_dev_secret_key" {
  secret_id = "sso-dashboard-dev-secret-key"
}

data "google_secret_manager_secret" "sso_dashboard_dev_oidc_client_secret" {
  secret_id = "sso-dashboard-dev-oidc-client-secret"
}

data "google_secret_manager_secret" "sso_dashboard_prod_secret_key" {
  secret_id = "sso-dashboard-prod-secret-key"
}

data "google_secret_manager_secret" "sso_dashboard_prod_oidc_client_secret" {
  secret_id = "sso-dashboard-prod-oidc-client-secret"
}
