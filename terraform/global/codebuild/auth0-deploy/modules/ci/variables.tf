variable "github_branch" {
}

variable "github_repo" {
}

variable "project_name" {
}

variable "environment" {
}

variable "enable_webhook" {
  default = "true"
}

variable "enable_ecr" {
  default = "true"
}

variable "build_image" {
  default = "aws/codebuild/docker:17.09.0"
}

