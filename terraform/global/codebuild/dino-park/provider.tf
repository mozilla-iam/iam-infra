#---
# Provider Configuration
#---

provider "aws" {
  region  = "us-west-2"
  // https://discuss.hashicorp.com/t/hcsec-2021-12-codecov-security-event-and-hashicorp-gpg-key-exposure/23512
  version = "~> 2.70.0"
}

terraform {
  backend "s3" {
    bucket = "eks-terraform-shared-state"
    key    = "global/codebuild/dino-park/terraform.tfstate"
    region = "us-west-2"
  }
}
