data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket = ""
    key    = "stage/us-west-2/vpc/terraform.tfstate"
    region = "us-west-2"
  }
}
