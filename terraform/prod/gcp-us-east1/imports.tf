import {
  id = "sso-dashboard-dev"
  to = google_compute_backend_service.sso_dashboard_dev
}

import {
  id = "sso-dashboard-dev"
  to = google_compute_region_network_endpoint_group.sso_dashboard_dev
}

import {
  id = "sso-dashboard-staging"
  to = google_compute_backend_service.sso_dashboard_staging
}

import {
  id = "sso-dashboard-staging"
  to = google_compute_region_network_endpoint_group.sso_dashboard_staging
}

import {
  id = "sso-dashboard-prod"
  to = google_compute_backend_service.sso_dashboard_prod
}

import {
  id = "sso-dashboard-prod"
  to = google_compute_region_network_endpoint_group.sso_dashboard_prod
}

import {
  id = "projects/iam-auth0/serviceAccounts/sso-dashboard@iam-auth0.iam.gserviceaccount.com"
  to = google_service_account.sso_dashboard
}

import {
  id = "projects/iam-auth0/serviceAccounts/sso-dashboard-staging@iam-auth0.iam.gserviceaccount.com"
  to = google_service_account.sso_dashboard_staging
}

import {
  id = "projects/iam-auth0/serviceAccounts/sso-dashboard-prod@iam-auth0.iam.gserviceaccount.com"
  to = google_service_account.sso_dashboard_prod
}
