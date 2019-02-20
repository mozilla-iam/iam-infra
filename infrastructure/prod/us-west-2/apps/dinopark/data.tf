data "aws_caller_identity" "current" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket = "eks-terraform-shared-state"
    key    = "prod/us-west-2/vpc/terraform.tfstate"
    region = "us-west-2"
  }
}

data "aws_kms_key" "ssm" {
  key_id = "alias/aws/ssm"
}

data "aws_ssm_parameter" "dinopark-db-password" {
  name  = "/iam/dinopark/${var.environment}/${var.region}/DB_PASSWORD"
  with_decryption = "true"
}

