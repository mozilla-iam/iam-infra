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
  instance-max              = 5
  instance-min              = 2
}

module "eks-production-01" {
  source                    = "./modules/eks-cluster"
  cluster-name              = "kubernetes-production-01"
  environment               = "production"
  region                    = "us-west-2"
  instance-type             = "c4.large"
  instance-desired-capacity = 5
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

#---
# Website resources
#---

module "dino-park-front-end-ci" {
  source       = "./modules/sites/dino-park-front-end"
  service_name = "dino-park-front-end"
}

module "dino-tree-ci" {
  source       = "./modules/sites/dino-tree"
  service_name = "dino-tree"
}

module "dino-park-search-ci" {
  source       = "./modules/sites/dino-park-search"
  service_name = "dino-park-search"
}

module "dino-park-mozillians-ci" {
  source       = "./modules/sites/dino-park-mozillians"
  service_name = "dino-park-mozillians"
}

module "graylog-resources" {
  source          = "./modules/sites/graylog"
  service_name    = "graylog"
  resource_vpc_id = "${module.resource-vpc-production.vpc-id}"
}
