#---
# Elasticsearch
#---

resource "aws_elasticsearch_domain" "dinopark-es" {
  domain_name           = "dinopark-test-${var.region}"
  elasticsearch_version = "6.4"

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
    automated_snapshot_start_hour = 23
  }

  vpc_options {
    subnet_ids = [module.vpc.private_subnets[0]]

    security_group_ids = [data.aws_security_group.es-allow-https.id]
  }

  tags = {
    Domain  = "dinopark-es"
    app     = "elasticsearch"
    env     = "test"
    region  = var.region
    project = "dinopark"
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
      "Resource": "arn:aws:es:us-west-2:${data.aws_caller_identity.current.account_id}:domain/dinopark-test-${var.region}/*"
    }
  ]
}
CONFIG

}

resource "aws_route53_record" "dinopark" {
  zone_id = data.aws_route53_zone.sso_allizom_org.zone_id
  name    = "dinopark.k8s.test.sso.allizom.org"
  type    = "A"

  alias {
    name                   = "dualstack.${data.aws_elb.dinopark-test-elb.dns_name}"
    zone_id                = data.aws_elb.dinopark-test-elb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "picture_api" {
  zone_id = data.aws_route53_zone.sso_allizom_org.zone_id
  name    = "picture.api.test.sso.allizom.org"
  type    = "A"

  alias {
    name                   = "dualstack.${data.aws_elb.dinopark-test-elb.dns_name}"
    zone_id                = data.aws_elb.dinopark-test-elb.zone_id
    evaluate_target_health = false
  }
}
