#---
# Elasticache cluster: Memcached 
#---

resource "aws_security_group" "dinopark-memcached" {
  name        = "dinopark-memcached-${var.environment}-${var.region}"
  description = "Traffic rules for Mozillians Memcached ${var.environment} in ${var.region}"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"
}

resource "aws_security_group_rule" "dinopark-memcached-ingress" {
  type                     = "ingress"
  from_port                = 11211
  to_port                  = 11211
  protocol                 = "-1"
  cidr_blocks              = ["10.0.0.0/16"]
  security_group_id        = "${aws_security_group.dinopark-memcached.id}"
}

resource "aws_security_group_rule" "dinopark-memcached-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  # TODO check if this can be restricted to 10.0.0.0/16
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.dinopark-memcached.id}"
}

resource "aws_elasticache_cluster" "dinopark-memcached-ec" {
  # Cluster Id is limited to 20 chars, that's why the "dinom" silly name.
  # "m" stands for memcached
  cluster_id           = "dinom-${var.environment}-${var.region}"
  engine               = "memcached"
  engine_version       = "1.4.34"
  node_type            = "cache.t2.micro"
  port                 = 11211
  num_cache_nodes      = 1
  parameter_group_name = "default.memcached1.4"

  tags {
    Name    = "dinopark-memcached-${var.environment}-${var.region}"
    app     = "memcached"
    env     = "${var.environment}"
    region  = "${var.region}"
    project = "dinopark"
  }
}

