data "google_cloud_run_v2_service" "sso_dashboard_prod" {
  name     = "sso-dashboard-prod"
  location = "us-east1"
}

resource "google_compute_region_network_endpoint_group" "sso_dashboard_prod" {
  name                  = "sso-dashboard-prod"
  network_endpoint_type = "SERVERLESS"
  region                = "us-east1"
  cloud_run {
    service = "sso-dashboard-prod"
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
