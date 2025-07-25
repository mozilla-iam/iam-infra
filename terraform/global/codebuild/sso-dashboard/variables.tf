variable "github_branch" {
  description = "Regular expression for branch matching"
  default     = "^master$|^production$"
}

variable "github_repo" {
  default = "https://github.com/mozilla-iam/sso-dashboard.git"
}

variable "project_name" {
  default = "sso-dashboard"
}

variable "build_image" {
  default = "aws/codebuild/standard:2.0-1.12.0"
}
