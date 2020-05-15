resource "aws_ecr_repository" "mozdef" {
  name = "fluentd-k8s-to-mozdef"

  image_scanning_configuration {
    scan_on_push = true
  }
}
