#---
# EKS cluster management
#---

module "eks-development-01" {
  source                    = "./modules/eks-cluster"
  cluster-name              = "kubernetes-development-01"
  environment               = "development"
  region                    = "us-west-2"
  instance-type             = "c4.large"
  instance-desired-capacity = 4
  instance-max              = 4
  instance-min              = 2
}

module "eks-production-01" {
  source                    = "./modules/eks-cluster"
  cluster-name              = "kubernetes-production-01"
  environment               = "production"
  region                    = "us-west-2"
  instance-type             = "c4.large"
  instance-desired-capacity = 4
  instance-max              = 10
  instance-min              = 4
  create-resource-vpc       = true
  peering-connection-id     = "${module.resource-vpc-production.peering-connection-id}"
}

#---
# The production resource VPC
# This includes resources for the following environments
#   - Prodction
#   - Staging
#---

module "resource-vpc-production" {
  source         = "./modules/resource-network"
  environment    = "production"
  region         = "us-west-2"
  vpc-id         = "${module.eks-production-01.vpc-id}"
  vpc-main-rt-id = "${module.eks-production-01.vpc-main-rt-id}"
}
