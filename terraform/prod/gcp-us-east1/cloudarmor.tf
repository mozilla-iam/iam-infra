# Copied from:
#   https://github.com/mozilla-it/webservices-infra/blob/3222c6c6151ab0af2bb8607d0629e0c537d4636f/0din/tf/modules/cloudarmor/cloudarmor.tf

resource "google_compute_project_cloud_armor_tier" "default" {
  cloud_armor_tier = "CA_ENTERPRISE_ANNUAL"
}

resource "google_compute_security_policy" "default" {
  name        = "default"
  description = "Default security policy"
  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = true
    }
  }
}

resource "google_compute_security_policy_rule" "adaptive_protection_auto_deploy" {
  security_policy = google_compute_security_policy.default.name
  description     = "adaptive protection auto deploy"
  action          = "deny(403)"
  priority        = 1000
  match {
    expr {
      expression = "evaluateAdaptiveProtectionAutoDeploy()"
    }
  }
  depends_on = [google_compute_project_cloud_armor_tier.default]
}
