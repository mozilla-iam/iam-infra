#---
# Create AWS resources for Mozillians
#---

# Addresses this issue:
# github.com/terraform-providers/terraform-provider-aws/issues/5218
#resource "aws_iam_service_linked_role" "es" {
#  aws_service_name = "es.amazonaws.com"
#}

module "mozillians-dinopark" {
  source = "./modules/mozillians"

  environment                         = "dino"
  vpc_id                              = "${data.terraform_remote_state.vpc.vpc_id}"
  elasticache_redis_instance_size     = "cache.t2.micro"
  elasticache_memcached_instance_size = "cache.t2.micro"
  rds_instance_class                  = "db.t2.small"
  cis_publisher_role_arn              = "arn:aws:iam::656532927350:role/CISPublisherRole"
  k8s_source_security_group           = "${data.terraform_remote_state.kubernetes.worker_security_group_id}"
}
