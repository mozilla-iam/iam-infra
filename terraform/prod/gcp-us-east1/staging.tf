# There may still be more resources we need to import (HTTP->HTTPS redirect).

data "google_cloud_run_v2_service" "sso_dashboard_staging" {
  name     = "sso-dashboard-staging"
  location = "us-east1"
}

resource "google_compute_region_network_endpoint_group" "sso_dashboard_staging" {
  name                  = "sso-dashboard-staging"
  network_endpoint_type = "SERVERLESS"
  region                = "us-east1"
  cloud_run {
    service = data.google_cloud_run_v2_service.sso_dashboard_staging.name
  }
}

resource "google_compute_backend_service" "sso_dashboard_staging" {
  name                            = "sso-dashboard-staging"
  port_name                       = "http"
  protocol                        = "HTTPS"
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  locality_lb_policy              = "ROUND_ROBIN"
  connection_draining_timeout_sec = 0
  security_policy                 = google_compute_security_policy.default.id
  backend {
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1
    group           = google_compute_region_network_endpoint_group.sso_dashboard_staging.id
  }
  log_config {
    enable      = true
    sample_rate = 1
  }
}

resource "google_compute_managed_ssl_certificate" "waf_sso_dashboard_staging" {
  name        = "waf-sso-dashboard-staging"
  description = "SSO Dashboard Staging (WAF)"
  type        = "MANAGED"
  managed {
    domains = [
      "waf-sso-dashboard-stage.gcp-iam-auth0.sso.mozilla.com",
    ]
  }
}

resource "google_compute_global_address" "sso_dashboard_staging" {
  name         = "sso-dashboard-staging"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}

resource "google_compute_url_map" "sso_dashboard_staging" {
  name            = "sso-dashboard-staging"
  default_service = google_compute_backend_service.sso_dashboard_staging.self_link
}

resource "google_compute_target_https_proxy" "waf_sso_dashboard_staging" {
  name = "sso-dashboard-stage-target-proxy"
  ssl_certificates = [
    google_compute_managed_ssl_certificate.waf_sso_dashboard_staging.self_link
  ]
  url_map = google_compute_url_map.sso_dashboard_staging.self_link
}

resource "google_compute_global_forwarding_rule" "sso_dashboard_staging" {
  name                  = "sso-dashboard-staging"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network_tier          = "PREMIUM"
  port_range            = "443-443"
  target                = google_compute_target_https_proxy.waf_sso_dashboard_staging.self_link
  ip_address            = google_compute_global_address.sso_dashboard_staging.address
}
