#---
# Provider Configuration
#---

provider "aws" {
  region = "us-west-2"
}

terraform {
  required_version = ">= 1.12.2"
  backend "s3" {
    bucket = "eks-terraform-shared-state"
    key    = "global/codebuild/sso-dashboard/terraform.tfstate"
    region = "us-west-2"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
