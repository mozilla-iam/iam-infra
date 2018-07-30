#---
# EKS cluster management
#---

module "eks-cluster-development" {
  source       = "./modules/eks-cluster"
  cluster-name = "kubernetes-development"
}

