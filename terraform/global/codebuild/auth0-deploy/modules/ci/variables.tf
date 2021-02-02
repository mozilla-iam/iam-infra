variable "github_head_ref" {
  description = "Git head reference used to determine which branches gets tbuilt"
}

variable "github_event_type" {
  description = "Event type which will trigger a deploy"
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

variable "source_version" {
  description = "Git reference to fetch code from."
  default     = ""
}

variable "fetch_submodules" {
  description = "Fetch submodules included in the repository"
  default     = "false"
}
