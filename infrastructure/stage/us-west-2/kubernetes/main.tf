#---
# EKS cluster
# Note: https://thinklumo.com/blue-green-node-deployment-kubernetes-eks-terraform/
#---

locals {
  cluster_name = "kubernetes-${var.environment}-${var.region}"

  worker_groups = [
    {
      name                  = "k8s-worker-blue"
      ami_id                = "ami-0e36fae01a5fa0d76"
      asg_desired_capacity  = "3"
      asg_max_size          = "10"
      asg_min_size          = "3"
      autoscaling_enabled   = true
      protect_from_scale_in = true
      instance_type         = "m4.large"
      root_volume_size      = "100"
      subnets               = "${join(",", data.terraform_remote_state.vpc.private_subnets)}"
      additional_userdata   = "aws s3 cp --recursive s3://audisp-json/ /tmp && sudo rpm -i /tmp/audisp-json-2.2.2-1.amazonlinux_x86_64.rpm && sudo mv /tmp/audit.rules /etc/audit/rules.d/ && sudo service auditd restart"
    },
    {
      name                  = "k8s-worker-green"
      ami_id                = "ami-0e36fae01a5fa0d76"
      asg_desired_capacity  = "0"
      asg_max_size          = "0"
      asg_min_size          = "0"
      autoscaling_enabled   = true
      protect_from_scale_in = true
      instance_type         = "m4.large"
      root_volume_size      = "100"
      subnets               = "${join(",", data.terraform_remote_state.vpc.private_subnets)}"
      additional_userdata   = "aws s3 cp --recursive s3://audisp-json/ /tmp && sudo rpm -i /tmp/audisp-json-2.2.2-1.amazonlinux_x86_64.rpm && sudo mv /tmp/audit.rules /etc/audit/rules.d/ && sudo service auditd restart"
    },
  ]

  tags = {
    "Environment" = "${var.environment}"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "1.7.0"

  cluster_name       = "${local.cluster_name}"
  cluster_version    = "1.10"
  subnets            = ["${data.terraform_remote_state.vpc.private_subnets}"]
  vpc_id             = "${data.terraform_remote_state.vpc.vpc_id}"
  worker_groups      = "${local.worker_groups}"
  worker_group_count = "2"
  tags               = "${local.tags}"
  # Do not create kubebernetes config file
  write_kubeconfig   = "false"
  # Enable me after updating the module
  #write_aws_auth_config = "false"
}
