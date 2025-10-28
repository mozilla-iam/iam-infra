data "google_cloud_run_v2_service" "sso_dashboard_prod" {
  name     = "sso-dashboard-prod"
  location = "us-east1"
}

resource "google_compute_region_network_endpoint_group" "sso_dashboard_prod" {
  name                  = "sso-dashboard-prod"
  network_endpoint_type = "SERVERLESS"
  region                = "us-east1"
  cloud_run {
    service = data.google_cloud_run_v2_service.sso_dashboard_prod.name
  }
}

resource "google_compute_backend_service" "sso_dashboard_prod" {
  name                            = "sso-dashboard-prod"
  port_name                       = "http"
  protocol                        = "HTTPS"
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  locality_lb_policy              = "ROUND_ROBIN"
  connection_draining_timeout_sec = 0
  security_policy                 = google_compute_security_policy.default.id
  backend {
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1
    group           = google_compute_region_network_endpoint_group.sso_dashboard_prod.id
  }
  log_config {
    enable      = true
    sample_rate = 1
  }
}

resource "google_compute_managed_ssl_certificate" "sso_dashboard_prod" {
  name        = "sso-dashboard-prod"
  description = "SSL Certificates for both Stage and Prod"
  type        = "MANAGED"
  managed {
    domains = ["sso.mozilla.com", "staging.sso.mozilla.com"]
  }
}

resource "google_compute_global_address" "sso_dashboard_prod" {
  name         = "sso-dashboard"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}

resource "google_compute_url_map" "sso_dashboard_prod" {
  name            = "sso-dashboard"
  default_service = google_compute_backend_service.sso_dashboard_prod.self_link
  host_rule {
    hosts        = ["staging.sso.mozilla.com"]
    path_matcher = "path-matcher-1"
  }
  path_matcher {
    default_service = google_compute_backend_service.sso_dashboard_staging.self_link
    name            = "path-matcher-1"
  }
}

resource "google_compute_target_https_proxy" "sso_dashboard_prod" {
  name = "sso-dashboard-target-proxy"
  ssl_certificates = [
    google_compute_managed_ssl_certificate.sso_dashboard_prod.self_link
  ]
  url_map = google_compute_url_map.sso_dashboard_prod.self_link
}

resource "google_compute_global_forwarding_rule" "sso_dashboard_prod" {
  name                  = "sso-dashboard"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network_tier          = "PREMIUM"
  port_range            = "443-443"
  target                = google_compute_target_https_proxy.sso_dashboard_prod.self_link
  ip_address            = google_compute_global_address.sso_dashboard_prod.address
}
