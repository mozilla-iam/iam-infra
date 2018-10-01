#---
# CodeBuild and GitHub webhooks
#---

resource "aws_codebuild_webhook" "webhook" {
  project_name  = "${aws_codebuild_project.build.name}"
  branch_filter = "${var.github_branch}"
}

resource "aws_codebuild_project" "build" {
  name          = "${var.project_name}-${var.environment}"
  description   = "CI pipeline for ${var.project_name}-${var.environment}"
  build_timeout = "5"
  service_role  = "${aws_iam_role.codebuild.arn}"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/docker:17.09.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = "true"

    environment_variable {
      "name"  = "DOCKER_REPO"
      "value" = "${aws_ecr_repository.registry.repository_url}"
    }
  }

  source {
    type     = "GITHUB"
    location = "${var.github_repo}"
  }

  tags {
    "App"         = "${var.project_name}"
    "Environment" = "${var.environment}"
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
  role = "${aws_iam_role.codebuild.name}"

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
    }
  ]
}
POLICY
}

#---
# ECR
#---

resource "aws_ecr_repository" "registry" {
  name = "${var.project_name}/${var.environment}"
}

resource "aws_ecr_repository_policy" "registrypolicy" {
  repository = "${aws_ecr_repository.registry.name}"

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
