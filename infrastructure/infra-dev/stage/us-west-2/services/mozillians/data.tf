data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket = "eks-terraform-shared-state"
    key    = "prod/us-west-2/vpc/terraform.tfstate"
    region = "us-west-2"
  }
}

data "terraform_remote_state" "kubernetes" {
  backend = "s3"

  config {
    bucket = "eks-terraform-shared-state"
    key    = "prod/us-west-2/kubernetes/terraform.tfstate"
    region = "us-west-2"
  }
}
