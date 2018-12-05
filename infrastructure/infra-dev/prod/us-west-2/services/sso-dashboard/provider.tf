#---
# Provider Configuration
#---

provider "aws" {
  region  = "us-west-2"
}

terraform {
  required_version = "~> 0.11"

  backend "s3" {
    bucket = ""
    key    = "prod/us-west-2/services/sso-dashboard/terraform.tfstate"
    region = "us-west-2"
  }
}
