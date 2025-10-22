resource "google_clouddeploy_delivery_pipeline" "sso-dashboard" {
  location    = "us-east1"
  name        = "sso-dashboard"
  description = "Deployment pipeline for sso-dashboard"

  serial_pipeline {
    stages {
      profiles  = ["dev"]
      target_id = google_clouddeploy_target.dev.target_id
    }

    stages {
      profiles  = ["staging"]
      target_id = google_clouddeploy_target.staging.target_id
    }

    stages {
      profiles  = ["prod"]
      target_id = google_clouddeploy_target.prod.target_id
    }
  }
}

resource "google_clouddeploy_target" "dev" {
  location    = "us-east1"
  name        = "dev"
  description = "Development target"
  run {
    location = "projects/iam-auth0/locations/us-east1"
  }
  execution_configs {
    usages            = ["RENDER", "DEPLOY"]
    execution_timeout = "3600s"
    service_account   = google_service_account.sso_dashboard.email
  }
  require_approval = false
}

resource "google_clouddeploy_target" "staging" {
  location    = "us-east1"
  name        = "staging"
  description = "Staging target"
  run {
    location = "projects/iam-auth0/locations/us-east1"
  }
  execution_configs {
    usages            = ["RENDER", "DEPLOY"]
    execution_timeout = "3600s"
    service_account   = google_service_account.sso_dashboard_staging.email
  }
  require_approval = false
}

resource "google_clouddeploy_target" "prod" {
  location    = "us-east1"
  name        = "prod"
  description = "Production target"
  run {
    location = "projects/iam-auth0/locations/us-east1"
  }
  execution_configs {
    usages            = ["RENDER", "DEPLOY"]
    execution_timeout = "3600s"
    service_account   = google_service_account.sso_dashboard_prod.email
  }
  require_approval = false
}
