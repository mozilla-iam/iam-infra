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
  name      = "sso-dashboard-dev"
  port_name = "http"
  protocol  = "HTTPS"
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
    client_ttl                   = 3600
    default_ttl                  = 3600
    max_ttl                      = 86400
    signed_url_cache_max_age_sec = 0
    cache_key_policy {
      include_host         = true
      include_protocol     = true
      include_query_string = true
    }
  }
}
