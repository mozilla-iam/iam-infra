data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "eks-terraform-shared-state"
    key    = "prod/us-west-2/vpc/terraform.tfstate"
    region = "us-west-2"
  }
}

