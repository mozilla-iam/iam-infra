#---
# Elasticsearch
#---

<<<<<<< HEAD
=======
<<<<<<< HEAD:terraform/stage/us-west-2/services/graylog/main.tf
#resource "aws_iam_service_linked_role" "es" {
#  aws_service_name = "es.amazonaws.com"
#}

=======
>>>>>>> master:terraform/prod/us-west-2/apps/dinopark/elasticsearch.tf
>>>>>>> master
resource "aws_security_group" "allow_https_from_kubernetes" {
  name        = "allow_https_from_kubernetes_to_es"
  description = "Allow HTTPS traffic from Kubernetes cluster"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 443
    protocol    = "tcp"
    security_groups = ["${data.terraform_remote_state.kubernetes.worker_security_group_id}"]
  }
}

<<<<<<< HEAD
resource "aws_elasticsearch_domain" "dinopark-es" {
  domain_name           = "dinopark-${var.environment}-${var.region}"
  elasticsearch_version = "2.3"
=======
<<<<<<< HEAD:terraform/stage/us-west-2/services/graylog/main.tf
resource "aws_elasticsearch_domain" "graylog" {
#  depends_on = ["aws_iam_service_linked_role.es"]

  domain_name           = "graylog-${var.environment}"
  elasticsearch_version = "5.6"
=======
resource "aws_elasticsearch_domain" "dinopark-es" {
  domain_name           = "dinopark-${var.environment}-${var.region}"
  elasticsearch_version = "2.3"
>>>>>>> master:terraform/prod/us-west-2/apps/dinopark/elasticsearch.tf
>>>>>>> master

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = 10
  }

  cluster_config {
<<<<<<< HEAD
    instance_count           = 3
    instance_type            = "t2.micro.elasticsearch"
=======
<<<<<<< HEAD:terraform/stage/us-west-2/services/graylog/main.tf
    instance_count           = 1
    instance_type            = "m3.medium.elasticsearch"
=======
    instance_count           = 3
    instance_type            = "t2.micro.elasticsearch"
>>>>>>> master:terraform/prod/us-west-2/apps/dinopark/elasticsearch.tf
>>>>>>> master
    dedicated_master_enabled = false
    zone_awareness_enabled   = false
  }

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  vpc_options {
    subnet_ids = ["${data.terraform_remote_state.vpc.private_subnets[0]}"]
    security_group_ids = ["${aws_security_group.allow_https_from_kubernetes.id}"]
  }

  tags {
    Domain  = "dinopark-shared-es"
    app     = "elasticsearch"
    env     = "${var.environment}"
    region  = "${var.region}"
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
      "Resource": "arn:aws:es:us-west-2:${data.aws_caller_identity.current.account_id}:domain/dinopark-shared-es-${var.environment}-${var.region}/*"
    }
  ]
}
CONFIG
}

