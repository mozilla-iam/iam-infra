data "aws_caller_identity" "current" {
}

data "aws_kms_key" "ssm" {
  key_id = "alias/aws/ssm"
}

#---
# CodeBuild and GitHub webhooks
#---

resource "aws_codebuild_webhook" "webhook" {
  count        = var.enable_webhook ? 1 : 0
  project_name = aws_codebuild_project.build.name

  filter_group {
    filter {
      type    = "EVENT"
      pattern = var.github_event_type
    }

    filter {
      type    = "HEAD_REF"
      pattern = var.github_head_ref
    }
  }
}

resource "aws_codebuild_project" "build" {
  name          = "${var.project_name}-${var.environment}"
  description   = "CI pipeline for ${var.project_name}-${var.environment}"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = var.build_image
    type            = "LINUX_CONTAINER"
    privileged_mode = "true"

    environment_variable {
      name = "DOCKER_REPO"
      value = coalesce(
        join("", aws_ecr_repository.registry.*.repository_url),
        "UNUSED",
      )
    }

    environment_variable {
      name  = "ENV"
      value = var.environment
    }
  }

  source {
    type     = "GITHUB"
    location = var.github_repo
  }

  tags = {
    "App"         = var.project_name
    "Environment" = var.environment
  }
}

#---
# IAM configuration
#---

resource "aws_iam_role" "codebuild" {
  name = "${var.project_name}-codebuild-${var.environment}"

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
        "ecr:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter*"
      ],
      "Resource": "arn:aws:ssm:us-west-2:${data.aws_caller_identity.current.account_id}:parameter/iam/${var.project_name}/${var.environment}/*"
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
  count = var.enable_ecr ? 1 : 0
  name  = "${var.project_name}/${var.environment}"
}

resource "aws_ecr_repository_policy" "registrypolicy" {
  count      = var.enable_ecr ? 1 : 0
  repository = aws_ecr_repository.registry[0].name

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

