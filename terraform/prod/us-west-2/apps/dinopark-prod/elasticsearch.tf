#---
# Elasticsearch
#---

resource "aws_elasticsearch_domain" "dinopark-es" {
  domain_name           = "dinopark-${var.environment}-${var.region}"
  elasticsearch_version = "6.4"

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = 10
  }

  cluster_config {
    instance_count           = 3
    instance_type            = "t2.medium.elasticsearch"
    dedicated_master_enabled = false
    zone_awareness_enabled   = false
  }

  snapshot_options {
    automated_snapshot_start_hour = 23
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
    security_group_ids = [data.aws_security_group.es-allow-https.id]
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

