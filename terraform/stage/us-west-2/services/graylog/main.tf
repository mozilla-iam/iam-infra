#---
# Elasticsearch
#---

#resource "aws_iam_service_linked_role" "es" {
#  aws_service_name = "es.amazonaws.com"
#}

resource "aws_security_group" "allow_https_from_kubernetes" {
  name        = "allow_https_from_kubernetes"
  description = "Allow HTTPS traffic from Kubernetes cluster"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port = 0
    to_port   = 443
    protocol  = "tcp"
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibility in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    security_groups = [data.terraform_remote_state.kubernetes.outputs.worker_security_group_id]
  }
}

resource "aws_elasticsearch_domain" "graylog" {
  #  depends_on = ["aws_iam_service_linked_role.es"]

  domain_name           = "graylog-${var.environment}"
  elasticsearch_version = "5.6"

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = 100
  }

  cluster_config {
    instance_count           = 1
    instance_type            = "m3.medium.elasticsearch"
    dedicated_master_enabled = false
    zone_awareness_enabled   = false
  }

  snapshot_options {
    automated_snapshot_start_hour = 20
  }

  vpc_options {
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibility in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    subnet_ids         = [data.terraform_remote_state.vpc.outputs.private_subnets[0]]
    security_group_ids = [aws_security_group.allow_https_from_kubernetes.id]
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

