#---
# EKS cluster
# Note: https://thinklumo.com/blue-green-node-deployment-kubernetes-eks-terraform/
#---

locals {
  cluster_name = "kubernetes-${var.environment}-${var.region}"

  tags = {
    "Environment" = var.environment
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.20.0"

  cluster_name                                       = local.cluster_name
  cluster_version                                    = "1.24"
  subnets                                            = module.vpc.private_subnets
  vpc_id                                             = module.vpc.vpc_id
  tags                                               = local.tags
  write_kubeconfig                                   = "false"
  manage_aws_auth                                    = "false"
  worker_create_cluster_primary_security_group_rules = true
  cluster_enabled_log_types                          = ["audit"]
  enable_irsa                                        = true
}

# Managed nodes
resource "aws_eks_node_group" "nodes" {
  cluster_name    = local.cluster_name
  node_group_name = local.cluster_name
  node_role_arn   = module.eks.worker_iam_role_arn
  subnet_ids      = module.vpc.private_subnets
  instance_types  = ["m5.large"]
  disk_size       = 20
  version         = module.eks.cluster_version

  scaling_config {
    desired_size = 5
    max_size     = 10
    min_size     = 5
  }

  labels = {
    node            = "managed"
    node_group_name = "${local.cluster_name}_worker"
  }
  tags = {
    Name = "iam-prod-eks-node"
  }
}


### Autoscaling policies
resource "aws_iam_role_policy_attachment" "workers_autoscaling" {
  policy_arn = aws_iam_policy.worker_autoscaling.arn
  role       = module.eks.worker_iam_role_name
}

resource "aws_iam_policy" "worker_autoscaling" {
  name_prefix = "eks-worker-autoscaling-${module.eks.cluster_id}"
  description = "EKS worker node autoscaling policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.worker_autoscaling.json
}

data "aws_iam_policy_document" "worker_autoscaling" {
  statement {
    sid    = "eksWorkerAutoscalingAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "eksWorkerAutoscalingOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${module.eks.cluster_id}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}

resource "helm_release" "aws-ebs-csi-driver" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  version    = "2.19.0"
  namespace  = "kube-system"

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.ebs_csi_irsa_role.iam_role_arn
  }
}

module "ebs_csi_irsa_role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name             = "ebs-csi-driver-prod"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.11.2"
  namespace  = "cert-manager"

  set {
    name  = "installCRDs"
    value = "true"
  }
}
