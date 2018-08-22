#---
# EKS cluster management
#---

module "eks-cluster-development" {
  source                    = "./modules/eks-cluster"
  cluster-name              = "kubernetes-development"
  instance-type             = "c4.large"
  instance-desired-capacity = 3
  instance-max              = 3
  instance-min              = 2
}

module "eks-cluster-production-01" {
  source                    = "./modules/eks-cluster"
  cluster-name              = "kubernetes-production-01"
  instance-type             = "c4.large"
  instance-desired-capacity = 3
  instance-max              = 3
  instance-min              = 2
}
