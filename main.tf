#---
# EKS cluster management
#---

module "eks-cluster-prod" {
  source       = "./modules/eks-cluster"
  cluster-name = "kubernetes-prod"
}

module "eks-cluster-development" {
  source       = "./modules/eks-cluster"
  cluster-name = "kubernetes-development"
}
