resource "aws_kinesis_stream" "cloudwatch2graylog" {
  name        = "Cloudwatch2Graylog"
  shard_count = 1
}

resource "aws_iam_role" "cloudwatch2kinesis" {
  name               = "cloudwatch-${var.region}-2-kinesis"
  assume_role_policy = "${data.aws_iam_policy_document.allow_cloudwatch_assume_role.json}"
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
  role   = "${aws_iam_role.cloudwatch2kinesis.id}"
  policy = "${data.aws_iam_policy_document.allow_cloudwatch_write_to_kinesis.json}"
}

data "aws_iam_policy_document" "allow_cloudwatch_write_to_kinesis" {
  statement {
    effect    = "Allow"
    actions   = ["kinesis:PutRecord"]
    resources = ["${aws_kinesis_stream.cloudwatch2graylog.arn}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["${aws_iam_role.cloudwatch2kinesis.arn}"]
  }
}

resource "aws_iam_role" "graylog_role" {
  name               = "graylog-role-${var.environment}-${var.region}"
  assume_role_policy = "${data.aws_iam_policy_document.allow_k8s_assume_role.json}"
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
  role   = "${aws_iam_role.graylog_role.id}"
  policy = "${data.aws_iam_policy_document.allow_access_to_kinesis.json}"
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

    resources = ["${aws_kinesis_stream.cloudwatch2graylog.arn}"]
  }
}

### Subscription filters (one per Cloudwatch loggroup):

resource "aws_cloudwatch_log_subscription_filter" "ldap_publisher_prod" {
  name            = "ldap-publisher-prod"
  role_arn        = "${aws_iam_role.cloudwatch2kinesis.arn}"
  log_group_name  = "/aws/lambda/ldap-publisher-production-handler"
  destination_arn = "${aws_kinesis_stream.cloudwatch2graylog.arn}"
  filter_pattern  = ""
  distribution    = "ByLogStream"
}

resource "aws_cloudwatch_log_subscription_filter" "change_service_prod" {
  name            = "change-service-prod"
  role_arn        = "${aws_iam_role.cloudwatch2kinesis.arn}"
  log_group_name  = "/aws/lambda/change-service-production-api"
  destination_arn = "${aws_kinesis_stream.cloudwatch2graylog.arn}"
  filter_pattern  = ""
  distribution    = "ByLogStream"
}

resource "aws_cloudwatch_log_subscription_filter" "hris_publisher_prod" {
  name            = "hris-publisher-prod"
  role_arn        = "${aws_iam_role.cloudwatch2kinesis.arn}"
  log_group_name  = "/aws/lambda/hris-publisher-production-handler"
  destination_arn = "${aws_kinesis_stream.cloudwatch2graylog.arn}"
  filter_pattern  = ""
  distribution    = "ByLogStream"
}

resource "aws_cloudwatch_log_subscription_filter" "profile_retrieval_prod" {
  name            = "profile-retrieval-prod"
  role_arn        = "${aws_iam_role.cloudwatch2kinesis.arn}"
  log_group_name  = "/aws/lambda/profile-retrieval-production-api"
  destination_arn = "${aws_kinesis_stream.cloudwatch2graylog.arn}"
  filter_pattern  = ""
  distribution    = "ByLogStream"
}

resource "aws_cloudwatch_log_subscription_filter" "vault_curator_prod" {
  name            = "vault-curator-prod"
  role_arn        = "${aws_iam_role.cloudwatch2kinesis.arn}"
  log_group_name  = "/aws/lambda/vault-curator-production-ensure-vaults"
  destination_arn = "${aws_kinesis_stream.cloudwatch2graylog.arn}"
  filter_pattern  = ""
  distribution    = "ByLogStream"
}

resource "aws_cloudwatch_log_subscription_filter" "webhook_notifications_prod" {
  name            = "webhook-notifications-prod"
  role_arn        = "${aws_iam_role.cloudwatch2kinesis.arn}"
  log_group_name  = "/aws/lambda/webhook-notifications-production-notifier"
  destination_arn = "${aws_kinesis_stream.cloudwatch2graylog.arn}"
  filter_pattern  = ""
  distribution    = "ByLogStream"
}
