provider "google" {
  project = "iam-auth0"
  region  = "us-east1"
}

terraform {
  backend "gcs" {
    bucket = "iam-auth0-terraform-state"
    prefix = "terraform/prod/gcp-us-east1/state"
  }
}
