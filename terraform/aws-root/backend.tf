terraform {
  backend "gcs" {
    bucket = "iam-auth0-terraform-state"
    prefix = "terraform/aws-root"
  }
}
