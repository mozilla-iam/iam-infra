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
