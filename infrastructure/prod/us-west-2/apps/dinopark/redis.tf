#---
# Elasticache cluster: Redis
#---

resource "aws_security_group" "dinopark-redis" {
  name        = "dinopark-redis-${var.environment}-${var.region}"
  description = "Traffic rules for Mozillians Redis ${var.environment} in ${var.region}"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"
}

resource "aws_security_group_rule" "dinopark-redis-ingress" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "-1"
  cidr_blocks              = ["10.0.0.0/16"]
  security_group_id        = "${aws_security_group.dinopark-redis.id}"
}

resource "aws_security_group_rule" "dinopark-redis-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  # TODO check if this can be restricted to 10.0.0.0/16
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.dinopark-redis.id}"
}

resource "aws_elasticache_cluster" "dinopark-redis-ec" {
  # Cluster Id is limited to 20 chars, that's why the "dinor" silly name.
  # "r" stands for redis
  cluster_id           = "dinor-${var.environment}-${var.region}"
  engine               = "redis"
  engine_version       = "2.8.24"
  node_type            = "cache.t2.micro"
  port                 = 6379
  num_cache_nodes      = 1
  parameter_group_name = "default.redis2.8"

  tags {
    Name    = "dinopark-redis-${var.environment}-${var.region}"
    app     = "redis"
    env     = "${var.environment}"
    region  = "${var.region}"
    project = "dinopark"
  }
}
