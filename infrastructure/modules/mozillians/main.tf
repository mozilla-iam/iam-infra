#---
# - Security groups
# - Elasticache
# - Redis
# - Memcached
#---

data "aws_caller_identity" "current" {}

data "aws_subnet_ids" "all" {
  vpc_id = "${var.vpc_id}"
}

#---
# Memcached security group
#---

resource "aws_security_group" "mozillians-memcached" {
  name        = "mozillians-memcached-${var.environment}"
  description = "Traffic rules for Mozillians Memcached"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "mozillians-memcached-ingress" {
  type                     = "ingress"
  from_port                = 11211
  to_port                  = 11211
  protocol                 = "-1"
  source_security_group_id = "${var.k8s_source_security_group}"
  security_group_id        = "${aws_security_group.mozillians-memcached.id}"
}

resource "aws_security_group_rule" "mozillians-memcached-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.mozillians-memcached.id}"
}

#---
# Redis security group
#---

resource "aws_security_group" "mozillians-redis" {
  name        = "mozillians-redis-${var.environment}"
  description = "Traffic rules for Mozillians Redis"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "mozillians-redis-ingress" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "-1"
  source_security_group_id = "${var.k8s_source_security_group}"
  security_group_id        = "${aws_security_group.mozillians-redis.id}"
}

resource "aws_security_group_rule" "mozillians-redis-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.mozillians-redis.id}"
}

#---
# RDS security group
#---

resource "aws_security_group" "mozillians-mysql" {
  name        = "mozillians-mysql-${var.environment}"
  description = "Traffic rules for Mozillians MySQL"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "mozillians-mysql-ingress" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "-1"
  source_security_group_id = "${var.k8s_source_security_group}"
  security_group_id        = "${aws_security_group.mozillians-mysql.id}"
}

resource "aws_security_group_rule" "mozillians-mysql-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.mozillians-mysql.id}"
}

#---
# Subnet groups
#---

resource "aws_elasticache_subnet_group" "sg" {
  name       = "elasticache-subnet-group-${var.environment}"
  subnet_ids = ["${data.aws_subnet_ids.all.ids}"]
}

#---
# Elasticache
#---

resource "aws_elasticache_cluster" "mozillians-redis-ec" {
  cluster_id           = "mozillians-${var.environment}"
  engine               = "redis"
  engine_version       = "2.8.24"
  node_type            = "${var.elasticache_redis_instance_size}"
  port                 = 6379
  num_cache_nodes      = 1
  parameter_group_name = "default.redis2.8"
  subnet_group_name    = "${aws_elasticache_subnet_group.sg.name}"

  tags {
    Name    = "mozillians-${var.environment}-redis"
    app     = "redis"
    env     = "${var.environment}"
    project = "mozillians"
  }
}

resource "aws_elasticache_cluster" "mozillians-memcached-ec" {
  cluster_id           = "mozcache-${var.environment}"
  engine               = "memcached"
  engine_version       = "1.4.34"
  node_type            = "${var.elasticache_memcached_instance_size}"
  port                 = 11211
  num_cache_nodes      = 1
  parameter_group_name = "default.memcached1.4"
  subnet_group_name    = "${aws_elasticache_subnet_group.sg.name}"

  tags {
    Name    = "mozillians-${var.environment}-memcached"
    app     = "memcached"
    env     = "${var.environment}"
    project = "mozillians"
  }
}

#---
# RDS MySQL database
#---

data "aws_route53_zone" "iam-infra" {
  name = "infra.iam.mozilla.com"
}

resource "aws_route53_record" "mysql-mozillians-dns" {
  zone_id = "${data.aws_route53_zone.iam-infra.zone_id}"
  name    = "mozillians-db-${var.environment}"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_db_instance.mysql-mozillians-db.address}"]
}

resource "aws_db_subnet_group" "apps-rds-subnetgroup" {
  name        = "apps-rds-subnetgroup-${var.environment}"
  description = "RDS subnet group for resource VPC"
  subnet_ids  = ["${data.aws_subnet_ids.all.ids}"]

  tags {
    Name = "apps-rds-subnetgroup-${var.environment}"
  }
}

resource "aws_db_instance" "mysql-mozillians-db" {
  allocated_storage          = 5
  engine                     = "mysql"
  engine_version             = "5.6.40"
  auto_minor_version_upgrade = false
  instance_class             = "${var.rds_instance_class}"
  publicly_accessible        = false
  backup_retention_period    = 14
  apply_immediately          = true
  multi_az                   = true
  storage_type               = "gp2"
  final_snapshot_identifier  = "mysql-mozillians-db-final-${var.environment}"
  name                       = "mozilliansdb"
  username                   = "root"
  password                   = "${var.mysql-mozillians-db_password}"
  db_subnet_group_name       = "${aws_db_subnet_group.apps-rds-subnetgroup.name}"
  parameter_group_name       = "default.mysql5.6"

  tags {
    Name    = "mysql-mozillians-db"
    app     = "mysql"
    env     = "${var.environment}"
    project = "mozillians"
  }
}

#---
# Elasticsearch
#---

resource "aws_elasticsearch_domain" "mozillians-es" {
  domain_name           = "mozillians-shared-es-${var.environment}"
  elasticsearch_version = "2.3"

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = 10
  }

  cluster_config {
    instance_count           = 3
    instance_type            = "t2.micro.elasticsearch"
    dedicated_master_enabled = false
    zone_awareness_enabled   = false
  }

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  vpc_options {
    subnet_ids = ["${data.aws_subnet_ids.all.ids[0]}"]
  }

  tags {
    Domain  = "mozillians-shared-es"
    app     = "elasticsearch"
    env     = "${var.environment}"
    project = "mozillians"
  }

  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [{
        "Action": "es:*",
        "Principal": "*",
        "Effect": "Allow"
    }]
}
CONFIG
}
