resource "google_clouddeploy_delivery_pipeline" "sso-dashboard" {
  location = "us-east1"
  name     = "sso-dashboard"
  description = "Deployment pipeline for sso-dashboard"

  serial_pipeline {
    stages {
      profiles  = ["dev"]
      target_id = "dev"
    }

    stages {
      profiles  = ["staging"]
      target_id = "staging"
    }

    stages {
      profiles  = ["prod"]
      target_id = "prod"
    }
  }
}

resource "google_clouddeploy_target" "dev" {
  location = "us-east1"
  name     = "dev"
  description = "Development target"
  run {
    location = "projects/iam-auth0/locations/us-east1"
  }
  execution_configs {
    usages            = ["RENDER", "DEPLOY"]
    execution_timeout = "3600s"
    service_account = "sso-dashboard-prod@iam-auth0.iam.gserviceaccount.com"
  }
  require_approval = false
}

resource "google_clouddeploy_target" "staging" {
  location = "us-east1"
  name     = "staging"
  description = "Staging target"
  run {
    location = "projects/iam-auth0/locations/us-east1"
  }
  execution_configs {
    usages            = ["RENDER", "DEPLOY"]
    execution_timeout = "3600s"
    service_account = "sso-dashboard-staging@iam-auth0.iam.gserviceaccount.com"
  }
  require_approval = false
}

resource "google_clouddeploy_target" "prod" {
  location = "us-east1"
  name     = "prod"
  description = "Production target"
  run {
    location = "projects/iam-auth0/locations/us-east1"
  }
  execution_configs {
    usages            = ["RENDER", "DEPLOY"]
    execution_timeout = "3600s"
    service_account = "sso-dashboard-prod@iam-auth0.iam.gserviceaccount.com"
  }
  require_approval = false
}
