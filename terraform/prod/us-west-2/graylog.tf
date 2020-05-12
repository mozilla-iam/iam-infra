#---
# Elasticsearch
#---

resource "aws_security_group" "allow_https_from_kubernetes" {
  name        = "allow_https_from_kubernetes"
  description = "Allow HTTPS traffic from Kubernetes cluster"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 0
    to_port   = 443
    protocol  = "tcp"
    security_groups = [module.eks.worker_security_group_id]
  }
}

resource "aws_elasticsearch_domain" "graylog" {
  domain_name           = "graylog-${var.environment}"
  elasticsearch_version = "5.6"

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
    subnet_ids         = [module.vpc.private_subnets[0]]
    security_group_ids = [aws_security_group.allow_https_from_kubernetes.id]
  }

  # TODO: Remove this when the issue is fixed on AWS Provider: https://github.com/terraform-providers/terraform-provider-aws/issues/5752
  lifecycle {
    ignore_changes = [log_publishing_options]
  }

  tags = {
    Service = "graylog-${var.environment}"
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
      "Resource": "arn:aws:es:us-west-2:${data.aws_caller_identity.current.account_id}:domain/graylog-${var.environment}/*"
    }
  ]
}
CONFIG

}

resource "aws_kinesis_stream" "cloudwatch2graylog" {
  name        = "Cloudwatch2Graylog"
  shard_count = 1
}

resource "aws_iam_role" "cloudwatch2kinesis" {
  name               = "cloudwatch-${var.region}-2-kinesis"
  assume_role_policy = data.aws_iam_policy_document.allow_cloudwatch_assume_role.json
}

data "aws_iam_policy_document" "allow_cloudwatch_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "allow_cloudwatch_write_kinesis" {
  name   = "allow_cloudwatch-${var.region}-write-to-kinesis"
  role   = aws_iam_role.cloudwatch2kinesis.id
  policy = data.aws_iam_policy_document.allow_cloudwatch_write_to_kinesis.json
}

data "aws_iam_policy_document" "allow_cloudwatch_write_to_kinesis" {
  statement {
    effect    = "Allow"
    actions   = ["kinesis:PutRecord"]
    resources = [aws_kinesis_stream.cloudwatch2graylog.arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.cloudwatch2kinesis.arn]
  }
}

resource "aws_iam_role" "graylog_role" {
  name               = "graylog-role-${var.environment}-${var.region}"
  assume_role_policy = data.aws_iam_policy_document.allow_k8s_assume_role.json
}

data "aws_iam_policy_document" "allow_k8s_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/kubernetes-prod-us-west-220181206181410238800000005"]
    }
  }
}

resource "aws_iam_role_policy" "allow_graylog_to_kinesis" {
  name   = "graylog-role-policy-${var.environment}-${var.region}"
  role   = aws_iam_role.graylog_role.id
  policy = data.aws_iam_policy_document.allow_access_to_kinesis.json
}

data "aws_iam_policy_document" "allow_access_to_kinesis" {
  statement {
    actions = [
      "cloudwatch:PutMetricData",
      "dynamodb:CreateTable",
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Scan",
      "dynamodb:UpdateItem",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaceAttribute",
      "ec2:DescribeNetworkInterfaces",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeLoadBalancers",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "kinesis:GetRecords",
      "kinesis:GetShardIterator",
      "kinesis:ListShards",
    ]

    resources = [aws_kinesis_stream.cloudwatch2graylog.arn]
  }
}

### Subscription filters (one per Cloudwatch loggroup):

resource "aws_cloudwatch_log_subscription_filter" "ldap_publisher_prod" {
  name            = "ldap-publisher-prod"
  role_arn        = aws_iam_role.cloudwatch2kinesis.arn
  log_group_name  = "/aws/lambda/ldap-publisher-production-handler"
  destination_arn = aws_kinesis_stream.cloudwatch2graylog.arn
  filter_pattern  = ""
  distribution    = "ByLogStream"
}

resource "aws_cloudwatch_log_subscription_filter" "change_service_prod" {
  name            = "change-service-prod"
  role_arn        = aws_iam_role.cloudwatch2kinesis.arn
  log_group_name  = "/aws/lambda/change-service-production-api"
  destination_arn = aws_kinesis_stream.cloudwatch2graylog.arn
  filter_pattern  = ""
  distribution    = "ByLogStream"
}

resource "aws_cloudwatch_log_subscription_filter" "hris_publisher_prod" {
  name            = "hris-publisher-prod"
  role_arn        = aws_iam_role.cloudwatch2kinesis.arn
  log_group_name  = "/aws/lambda/hris-publisher-production-handler"
  destination_arn = aws_kinesis_stream.cloudwatch2graylog.arn
  filter_pattern  = ""
  distribution    = "ByLogStream"
}

resource "aws_cloudwatch_log_subscription_filter" "profile_retrieval_prod" {
  name            = "profile-retrieval-prod"
  role_arn        = aws_iam_role.cloudwatch2kinesis.arn
  log_group_name  = "/aws/lambda/profile-retrieval-production-api"
  destination_arn = aws_kinesis_stream.cloudwatch2graylog.arn
  filter_pattern  = ""
  distribution    = "ByLogStream"
}

resource "aws_cloudwatch_log_subscription_filter" "vault_curator_prod" {
  name            = "vault-curator-prod"
  role_arn        = aws_iam_role.cloudwatch2kinesis.arn
  log_group_name  = "/aws/lambda/vault-curator-production-ensure-vaults"
  destination_arn = aws_kinesis_stream.cloudwatch2graylog.arn
  filter_pattern  = ""
  distribution    = "ByLogStream"
}

resource "aws_cloudwatch_log_subscription_filter" "webhook_notifications_prod" {
  name            = "webhook-notifications-prod"
  role_arn        = aws_iam_role.cloudwatch2kinesis.arn
  log_group_name  = "/aws/lambda/webhook-notifications-production-notifier"
  destination_arn = aws_kinesis_stream.cloudwatch2graylog.arn
  filter_pattern  = ""
  distribution    = "ByLogStream"
}

resource "aws_cloudwatch_log_subscription_filter" "auth0_publisher_prod" {
  name            = "auth0-publisher-prod"
  role_arn        = aws_iam_role.cloudwatch2kinesis.arn
  log_group_name  = "/aws/lambda/auth0-publisher-production-handler"
  destination_arn = aws_kinesis_stream.cloudwatch2graylog.arn
  filter_pattern  = ""
  distribution    = "ByLogStream"
}

resource "aws_route53_record" "graylog" {
  zone_id = data.aws_route53_zone.infra_iam.zone_id
  name    = "graylog.infra.iam.mozilla.com"
  type    = "A"

  alias {
    name                   = "dualstack.${data.aws_elb.k8s-elb.dns_name}"
    zone_id                = data.aws_elb.k8s-elb.zone_id
    evaluate_target_health = false
  }
}

