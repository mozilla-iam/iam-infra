variable "service_name" {}

data "aws_caller_identity" "current" {}

data "aws_kms_key" "ssm" {
  key_id = "alias/aws/ssm"
}

#---
# CodeBuild and webhook
#---

resource "aws_codebuild_project" "build" {
  name          = var.service_name
  description   = "CI pipeline for ${var.service_name}"
  build_timeout = "30"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/docker:17.09.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = "true"

    environment_variable {
      name  = "DOCKER_REPO"
      value = aws_ecr_repository.registry.repository_url
    }

    environment_variable {
      name  = "PROJECT_NAME"
      value = var.service_name
    }

    environment_variable {
      name  = "CLUSTER_NAME"
      value = "kubernetes-production-01"
    }

    environment_variable {
      name  = "DEPLOY_TOKEN"
      value = "/iam/kubernetes/DEPLOY_TOKEN"
      type  = "PARAMETER_STORE"
    }
  }

  source {
    type      = "GITHUB"
    location  = "https://github.com/mozilla/mozillians.git"
  }

  tags = {
    App = var.service_name
  }
}

#---
# IAM configuration
#---

resource "aws_iam_role" "codebuild" {
  name = "${var.service_name}-codebuild"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild" {
  role = aws_iam_role.codebuild.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs",
        "ecr:*",
        "eks:DescribeCluster"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter*"
      ],
      "Resource": "arn:aws:ssm:us-west-2:${data.aws_caller_identity.current.account_id}:parameter/iam/${var.service_name}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter*"
      ],
      "Resource": "arn:aws:ssm:us-west-2:${data.aws_caller_identity.current.account_id}:parameter/iam/kubernetes/DEPLOY_TOKEN"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:us-west-2:${data.aws_caller_identity.current.account_id}:key/${data.aws_kms_key.ssm.id}"
    }
  ]
}
POLICY
}

#---
# ECR
#---

resource "aws_ecr_repository" "registry" {
  name = var.service_name
}

resource "aws_ecr_repository_policy" "registrypolicy" {
  repository = aws_ecr_repository.registry.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
              "AWS": "${aws_iam_role.codebuild.arn}"
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}
