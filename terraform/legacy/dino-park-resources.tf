#---
# Elasticsearch
#---

data "aws_caller_identity" "current" {}

data "aws_subnet_ids" "all" {
  vpc_id = "${module.resource-vpc-production.vpc-id}"
}

data "aws_security_group" "resource-vpc" {
  vpc_id = "${module.resource-vpc-production.vpc-id}"
  name   = "default"
}

resource "aws_elasticsearch_domain" "dinopark-es" {
  domain_name           = "mozillians-es-dinopark"
  elasticsearch_version = "6.3"

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = 10
  }

  cluster_config {
    instance_count           = 3
    instance_type            = "t2.small.elasticsearch"
    dedicated_master_enabled = false
    zone_awareness_enabled   = false
  }

  snapshot_options {
    automated_snapshot_start_hour = 17
  }

  vpc_options {
    subnet_ids = ["${data.aws_subnet_ids.all.ids[0]}"]
    security_group_ids = ["${data.aws_security_group.resource-vpc.id}"]
  }

  tags {
    Domain  = "mozillians-dinopark-es"
    app     = "elasticsearch"
    env     = "dinopark"
    project = "mozillians"
  }

  access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::320464205386:role/dino-park-staging"
      },
      "Action": "es:*",
      "Resource": "arn:aws:es:us-west-2:320464205386:domain/mozillians-es-dinopark/*"
    }
  ]
}
CONFIG
}
