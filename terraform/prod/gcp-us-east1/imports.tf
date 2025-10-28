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

import {
  id = "projects/iam-auth0/global/sslCertificates/sso-dashboard-dev"
  to = google_compute_managed_ssl_certificate.sso_dashboard_dev
}

import {
  id = "projects/iam-auth0/global/forwardingRules/sso-dashboard-dev"
  to = google_compute_global_forwarding_rule.sso_dashboard_dev
}

import {
  id = "projects/iam-auth0/global/addresses/sso-dashboard-dev"
  to = google_compute_global_address.sso_dashboard_dev
}

import {
  id = "projects/iam-auth0/global/targetHttpsProxies/sso-dashboard-dev-target-proxy"
  to = google_compute_target_https_proxy.sso_dashboard_dev
}

import {
  id = "projects/iam-auth0/global/urlMaps/sso-dashboard-dev"
  to = google_compute_url_map.sso_dashboard_dev
}

import {
  id = "projects/iam-auth0/global/sslCertificates/sso-dashboard-prod"
  to = google_compute_managed_ssl_certificate.sso_dashboard_prod
}

import {
  id = "projects/iam-auth0/global/forwardingRules/sso-dashboard"
  to = google_compute_global_forwarding_rule.sso_dashboard_prod
}

import {
  id = "projects/iam-auth0/global/addresses/sso-dashboard"
  to = google_compute_global_address.sso_dashboard_prod
}

import {
  id = "projects/iam-auth0/global/targetHttpsProxies/sso-dashboard-target-proxy"
  to = google_compute_target_https_proxy.sso_dashboard_prod
}

import {
  id = "projects/iam-auth0/global/urlMaps/sso-dashboard"
  to = google_compute_url_map.sso_dashboard_prod
}
