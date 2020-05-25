#---
# Provider Configuration
#---

provider "aws" {
  region = "us-west-2"
}

terraform {

  backend "s3" {
    bucket = "it-sre-state-32046420538"
    key    = "state/terraform.tfstate"
    region = "us-west-2"
  }
}

