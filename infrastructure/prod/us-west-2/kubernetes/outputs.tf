output "cluster_name" {
  value = "${module.eks.cluster_id}"
}

output "worker_iam_role_arn" {
  value = "${module.eks.worker_iam_role_arn}"
}

output "worker_security_group_id" {
  value = "${module.eks.worker_security_group_id}"
}
