#---
# Provides a VPC for the stage environment
#---

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "kubernetes-${var.environment}-${var.region}"
  cidr = "10.0.0.0/16"

  azs = [
    data.aws_availability_zones.available.names[0],
    data.aws_availability_zones.available.names[1],
    data.aws_availability_zones.available.names[2],
  ]

  enable_nat_gateway = true
  single_nat_gateway = true

  private_subnets = ["10.0.0.0/19", "10.0.64.0/19", "10.0.128.0/19"]
  public_subnets  = ["10.0.32.0/19", "10.0.96.0/19", "10.0.160.0/19"]

  tags = {
    "Environment"                                                       = var.environment
    "kubernetes.io/cluster/kubernetes-${var.environment}-${var.region}" = "shared"
    "k8s.io/cluster-autoscaler/enabled"                                 = "true"
  }
}

