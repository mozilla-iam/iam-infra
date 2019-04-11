#---
# Create AWS resources for Mozillians
#---

# Addresses this issue:
# github.com/terraform-providers/terraform-provider-aws/issues/5218
resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}

module "mozillians-dino-park-staging" {
  source = "./modules/mozillians"

  environment                         = "dino"
  vpc_id                              = "${module.resource-vpc-production.vpc-id}"
  elasticache_redis_instance_size     = "cache.t2.micro"
  elasticache_memcached_instance_size = "cache.t2.micro"
  rds_instance_class                  = "db.t2.small"
  cis_publisher_role_arn              = "arn:aws:iam::656532927350:role/CISPublisherRole"
  k8s_source_security_group           = "${module.eks-production-01.node-security-group}"
}

module "mozillians-staging" {
  source = "./modules/mozillians"

  environment                         = "stage"
  vpc_id                              = "${module.resource-vpc-production.vpc-id}"
  elasticache_redis_instance_size     = "cache.t2.micro"
  elasticache_memcached_instance_size = "cache.t2.micro"
  rds_instance_class                  = "db.t2.small"
  cis_publisher_role_arn              = "arn:aws:iam::656532927350:role/CISPublisherRole"
  k8s_source_security_group           = "${module.eks-production-01.node-security-group}"
}

#---
# Setting environment to 'production' will result in an error. Using shorthand
# cluster_id cannot exceed 20 bytes
#---

module "mozillians-production" {
  source = "./modules/mozillians"

  environment                         = "prod"
  vpc_id                              = "${module.resource-vpc-production.vpc-id}"
  elasticache_redis_instance_size     = "cache.t2.micro"
  elasticache_memcached_instance_size = "cache.t2.micro"
  rds_instance_class                  = "db.t2.medium"
  cis_publisher_role_arn              = "arn:aws:iam::371522382791:role/CISPublisherRole"
  k8s_source_security_group           = "${module.eks-production-01.node-security-group}"
}
