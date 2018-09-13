variable "mysql-mozillians-db_password" {}

module "mozillians-staging" {
    source                              = "./modules/mozillians"

    environment                         = "stage"
    vpc_id                              = "${module.resource-vpc-production.vpc-id}"
    elasticache_redis_instance_size     = "cache.t2.micro"
    elasticache_memcached_instance_size = "cache.t2.micro"
    rds_instance_class                  = "db.t2.small"
    cis_publisher_role_arn              = "arn:aws:iam::656532927350:role/CISPublisherRole"
    mysql-mozillians-db_password        = "${var.mysql-mozillians-db_password}"
}

#---
# Setting environment to 'production' will result in an error. Using shorthand
# cluster_id cannot exceed 20 bytes
#---

module "mozillians-production" {
    source                              = "./modules/mozillians"

    environment                         = "prod"
    vpc_id                              = "${module.resource-vpc-production.vpc-id}"
    elasticache_redis_instance_size     = "cache.t2.micro"
    elasticache_memcached_instance_size = "cache.t2.micro"
    rds_instance_class                  = "db.t2.medium"
    cis_publisher_role_arn              = "arn:aws:iam::371522382791:role/CISPublisherRole"
    mysql-mozillians-db_password        = "${var.mysql-mozillians-db_password}"
}
