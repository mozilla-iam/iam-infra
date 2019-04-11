variable "project_name" {
  description = "Your project's name without spaces"
  default     = "template"
}

variable "github_repo" {
  default = "https://github.com/The-smooth-operator/test-deployment-pipeline"
}

variable "github_branch" {
  description = "Regular expression for branch matching"
  default     = "^master$|^production$"
}

variable "buildspec_file" {
  description = "Path and name of your builspec file"
  default     = "buildspec-k8s.yml"
}

# Choose the cluster you want to deploy to. Possible values:
#  - "kubernetes-stage-us-west-2" for deploying to development cluster
#  - "kubernetes-prod-us-west-2" for deploying to production cluster
variable "deploy_environment" {
  description = "Selects the cluster where to deploy"
  default     = "kubernetes-stage-us-west-2"
}

# Find all the supported images by AWS here: 
# https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
variable "build_image" {
  default = "aws/codebuild/docker:18.09.0"
}

