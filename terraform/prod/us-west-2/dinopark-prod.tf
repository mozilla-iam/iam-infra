#---
# Elasticsearch
#---

resource "aws_elasticsearch_domain" "dinopark-es-prod" {
  domain_name           = "dinopark-${var.environment}-${var.region}"
  elasticsearch_version = "6.4"

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = 10
  }

  cluster_config {
    instance_count           = 3
    instance_type            = "m5.large.elasticsearch"
    dedicated_master_enabled = true
    dedicated_master_count   = 3
    dedicated_master_type    = "m5.large.elasticsearch"
    zone_awareness_enabled   = false
  }

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  vpc_options {
    subnet_ids         = [module.vpc.private_subnets[0]]
    security_group_ids = [data.aws_security_group.es-allow-https.id]
  }

  log_publishing_options {
    cloudwatch_log_group_arn = "arn:aws:logs:us-west-2:320464205386:log-group:/aws/aes/domains/dinopark-prod-us-west-2/es-dinopark-prod-logs"
    enabled                  = true
    log_type                 = "ES_APPLICATION_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = "arn:aws:logs:us-west-2:320464205386:log-group:/aws/aes/domains/dinopark-prod-us-west-2/es-dinopark-prod-logs"
    enabled                  = true
    log_type                 = "SEARCH_SLOW_LOGS"
  }

  tags = {
    Domain  = "dinopark-es"
    app     = "elasticsearch"
    env     = var.environment
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
      "Resource": "arn:aws:es:us-west-2:${data.aws_caller_identity.current.account_id}:domain/dinopark-${var.environment}-${var.region}/*"
    }
  ]
}
CONFIG

}

resource "aws_route53_record" "dinopark_prod" {
  zone_id = data.aws_route53_zone.sso_mozilla_com.zone_id
  name    = "dinopark.k8s.sso.mozilla.com"
  type    = "A"

  alias {
    name                   = "dualstack.${data.aws_elb.dinopark-prod-elb.dns_name}"
    zone_id                = data.aws_elb.dinopark-prod-elb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "picture_api_prod" {
  zone_id = data.aws_route53_zone.sso_mozilla_com.zone_id
  name    = "picture.api.sso.mozilla.com"
  type    = "A"

  alias {
    name                   = "dualstack.${data.aws_elb.dinopark-prod-elb.dns_name}"
    zone_id                = data.aws_elb.dinopark-prod-elb.zone_id
    evaluate_target_health = false
  }
}
