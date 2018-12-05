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
    key    = "stage/us-west-2/kubernetes/terraform.tfstate"
    region = "us-west-2"
  }
}
