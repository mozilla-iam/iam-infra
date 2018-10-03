variable "github_branch" {}
variable "github_repo" {}
variable "project_name" {}
variable "environment" {}

variable "enable_webhook" {
  default = "true"
}

variable "enable_ecr" {
  default = "true"
}
