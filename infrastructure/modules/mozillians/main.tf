#---
# Elasticache
# - Redis
# - Memcached
#---

data "aws_caller_identity" "current" {}

data "aws_subnet_ids" "all" {
  vpc_id = "${var.vpc_id}"
}

resource "aws_elasticache_subnet_group" "sg" {
  name       = "elasticache-subnet-group-${var.environment}"
  subnet_ids = ["${data.aws_subnet_ids.all.ids}"]
}

resource "aws_elasticache_cluster" "mozillians-redis-ec" {
    cluster_id                 = "mozillians-${var.environment}"
    engine                     = "redis"
    engine_version             = "2.8.24"
    node_type                  = "${var.elasticache_redis_instance_size}"
    port                       = 6379
    num_cache_nodes            = 1
    parameter_group_name       = "default.redis2.8"
    subnet_group_name          = "${aws_elasticache_subnet_group.sg.name}"
    tags {
        Name                   = "mozillians-${var.environment}-redis"
        app                    = "redis"
        env                    = "${var.environment}"
        project                = "mozillians"
    }
}

resource "aws_elasticache_cluster" "mozillians-memcached-ec" {
    cluster_id                 = "mozcache-${var.environment}"
    engine                     = "memcached"
    engine_version             = "1.4.34"
    node_type                  = "${var.elasticache_memcached_instance_size}"
    port                       = 11211
    num_cache_nodes            = 1
    parameter_group_name       = "default.memcached1.4"
    subnet_group_name          = "${aws_elasticache_subnet_group.sg.name}"
    tags {
        Name                   = "mozillians-${var.environment}-memcached"
        app                    = "memcached"
        env                    = "${var.environment}"
        project                = "mozillians"
    }
}

#---
# RDS MySQL database
#---

resource "aws_db_subnet_group" "apps-rds-subnetgroup" {
    name = "apps-rds-subnetgroup-${var.environment}"
    description = "RDS subnet group for resource VPC"
    subnet_ids = ["${data.aws_subnet_ids.all.ids}"]
    tags {
        Name = "apps-rds-subnetgroup-${var.environment}"
    }
}

resource "aws_db_instance" "mysql-mozillians-db" {
    allocated_storage    = 5
    engine               = "mysql"
    engine_version       = "5.6.27"
    instance_class       = "${var.rds_instance_class}"
    publicly_accessible  = false
    backup_retention_period = 14
    apply_immediately    = true
    multi_az             = true
    storage_type         = "gp2"
    final_snapshot_identifier = "mysql-mozillians-db-final-${var.environment}"
    name                 = "mozilliansdb"
    username             = "root"
    password             = "${var.mysql-mozillians-db_password}"
    db_subnet_group_name = "${aws_db_subnet_group.apps-rds-subnetgroup.name}"
    parameter_group_name = "default.mysql5.6"
    tags {
        Name                = "mysql-mozillians-db"
        app                 = "mysql"
        env                 = "${var.environment}"
        project             = "mozillians"
    }
}

#---
# Elasticsearch
#---

# resource "aws_elasticsearch_domain" "mozillians-es" {
#     domain_name                       = "mozillians-shared-es-${var.environment}"
#     elasticsearch_version             = "2.3"

#     ebs_options {
#         ebs_enabled                   = true
#         volume_type                   = "gp2"
#         volume_size                   = 10
#     }

#     cluster_config {
#         instance_count                = 3
#         instance_type                 = "t2.micro.elasticsearch"
#         dedicated_master_enabled      = false
#         zone_awareness_enabled        = false
#     }

#     snapshot_options {
#         automated_snapshot_start_hour = 23
#     }
    
#     tags {
#       Domain                          = "mozillians-shared-es"
#       app                             = "elasticsearch"
#       env                             = "${var.environment}"
#       project                         = "mozillians"
#     }

#     access_policies = <<CONFIG
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Action": "es:*",
#             "Principal": "*",
#             "Effect": "Allow",
#             "Condition": {
#                 "IpAddress": {"aws:SourceIp": ["52.91.164.226"]}
#             }
#         }
#     ]
# }
# CONFIG
# }
