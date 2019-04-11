data "aws_caller_identity" "current" {}

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

data "aws_route53_zone" "infra_iam" {
<<<<<<< HEAD
  name = "infra.iam.mozilla.com."
}

data "aws_elb" "k8s-elb" {
  name = "a00435690f99111e8989b0ace417809a"
}
=======
 name = "infra.iam.mozilla.com."
}

data "aws_elb" "k8s-elb" {
 name = "a00435690f99111e8989b0ace417809a"
}

>>>>>>> master
