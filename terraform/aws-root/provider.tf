provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      Managed-By = "Terraform"
      Owner      = "IAM"
    }
  }
}
