resource "aws_ecr_repository" "mozdef" {
  name = "fluentd-k8s-to-mozdef"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "graylog-oidc-proxy" {
  name = "graylog-oidc-proxy"

  image_scanning_configuration {
    scan_on_push = true
  }
}
