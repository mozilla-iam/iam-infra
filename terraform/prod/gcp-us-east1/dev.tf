# Right now, we only have the SSO Dashboard imported. There's a couple of other
# things which are dev but aren't included in this file, such as the: Auth0
# logging webhook (CloudDeploy) and User Unblocking App (AppEngine).
#
# At some point, once we start importing/managing more things in Terraform,
# we'll want to split this file up.

data "google_cloud_run_v2_service" "sso_dashboard_dev" {
  name     = "sso-dashboard-dev"
  location = "us-east1"
}

resource "google_compute_region_network_endpoint_group" "sso_dashboard_dev" {
  name                  = "sso-dashboard-dev"
  network_endpoint_type = "SERVERLESS"
  region                = "us-east1"
  cloud_run {
    service = data.google_cloud_run_v2_service.sso_dashboard_dev.name
  }
}

resource "google_compute_backend_service" "sso_dashboard_dev" {
  name                            = "sso-dashboard-dev"
  port_name                       = "http"
  protocol                        = "HTTPS"
  compression_mode                = "DISABLED"
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  locality_lb_policy              = "ROUND_ROBIN"
  connection_draining_timeout_sec = 0
  security_policy                 = google_compute_security_policy.default.id
  backend {
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1
    group           = google_compute_region_network_endpoint_group.sso_dashboard_dev.id
  }
  enable_cdn = true
  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    signed_url_cache_max_age_sec = 0
    cache_key_policy {
      include_host         = true
      include_protocol     = true
      include_query_string = true
    }
  }
}

resource "google_compute_managed_ssl_certificate" "waf_sso_dashboard_dev" {
  name        = "waf-sso-dashboard-dev"
  description = "SSO Dashboard Dev (WAF)"
  type        = "MANAGED"
  managed {
    domains = [
      "waf-sso-dashboard-dev.gcp-iam-auth0.sso.mozilla.com",
    ]
  }
}

resource "google_compute_global_address" "sso_dashboard_dev" {
  name         = "sso-dashboard-dev"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}

resource "google_compute_url_map" "sso_dashboard_dev" {
  name            = "sso-dashboard-dev"
  default_service = google_compute_backend_service.sso_dashboard_dev.self_link
}

resource "google_compute_target_https_proxy" "sso_dashboard_dev" {
  name = "sso-dashboard-dev-target-proxy"
  ssl_certificates = [
    google_compute_managed_ssl_certificate.waf_sso_dashboard_dev.self_link,
  ]
  url_map = google_compute_url_map.sso_dashboard_dev.self_link
}

resource "google_compute_global_forwarding_rule" "sso_dashboard_dev" {
  name                  = "sso-dashboard-dev"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network_tier          = "PREMIUM"
  port_range            = "443-443"
  target                = google_compute_target_https_proxy.sso_dashboard_dev.self_link
  ip_address            = google_compute_global_address.sso_dashboard_dev.address
}
