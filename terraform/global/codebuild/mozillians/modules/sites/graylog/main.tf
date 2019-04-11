#---
# Elasticsearch
#---

variable "service_name" {}
variable "resource_vpc_id" {}

data "aws_caller_identity" "current" {}

data "aws_subnet_ids" "all" {
  vpc_id = "${var.resource_vpc_id}"
}

data "aws_security_group" "resource-vpc" {
  vpc_id = "${var.resource_vpc_id}"
  name   = "default"
}

resource "aws_elasticsearch_domain" "graylog-es" {
  domain_name           = "${var.service_name}"
  elasticsearch_version = "6.3"

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = 100
  }

  cluster_config {
    instance_count           = 3
    instance_type            = "m3.medium.elasticsearch"
    dedicated_master_enabled = false
    zone_awareness_enabled   = false
  }

  snapshot_options {
    automated_snapshot_start_hour = 20
  }

  vpc_options {
    subnet_ids = ["${data.aws_subnet_ids.all.ids[0]}"]
    security_group_ids = ["${data.aws_security_group.resource-vpc.id}"]
  }

  tags {
    Domain  = "${var.service_name}-es"
    app     = "elasticsearch"
    env     = "kubernetes"
    project = "${var.service_name}"
  }

  access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "*"
        ]
      },
      "Action": [
        "es:*"
      ],
      "Resource": "arn:aws:es:us-west-2:${data.aws_caller_identity.current.account_id}:domain/${var.service_name}/*"
    }
  ]
}
CONFIG
}
