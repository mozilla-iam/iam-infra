data "aws_caller_identity" "current" {}

data "aws_cloudwatch_log_group" "graylog-prod" {
  name = "/aws/elasticsearch/domains/graylog-${var.environment}"
}
