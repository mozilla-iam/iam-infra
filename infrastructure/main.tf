#---
# EKS cluster management
#---

module "eks-development-01" {
  source                    = "./modules/eks-cluster"
  cluster-name              = "kubernetes-development-01"
  instance-type             = "c4.large"
  instance-desired-capacity = 4
  instance-max              = 4
  instance-min              = 2
  create-resource-vpc       = true
}

module "eks-production-01" {
  source                    = "./modules/eks-cluster"
  cluster-name              = "kubernetes-production-01"
  instance-type             = "c4.large"
  instance-desired-capacity = 4
  instance-max              = 10
  instance-min              = 4
  create-resource-vpc       = false
}
