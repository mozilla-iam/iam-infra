output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "worker_iam_role_arn" {
  value = module.eks.worker_iam_role_arn
}
