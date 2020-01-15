#---
# Provider Configuration
#---

provider "aws" {
  region = "us-west-2"
}

terraform {

  backend "s3" {
    bucket = "eks-terraform-shared-state"
    key    = "stage/us-west-2/services/dino-park/terraform.tfstate"
    region = "us-west-2"
  }
}

