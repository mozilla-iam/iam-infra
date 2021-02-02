#---
# Create CI pipeline:
#   - CodeBuild and ECR
#   - Uses OAuth to create webhooks in GitHub repositories
#
# https://docs.aws.amazon.com/codepipeline/latest/userguide/GitHub-authentication.html
#---

module "auth0-deploy-ci-stage" {
  source = "./modules/ci"

  project_name      = "auth0-deploy"
  environment       = "stage"
  github_repo       = "https://github.com/mozilla-iam/auth0-deploy"
  github_head_ref   = "refs/heads/master"
  github_event_type = "PUSH"
  enable_webhook    = "true"
  enable_ecr        = "false"
  build_image       = "aws/codebuild/python:3.6.5"
}

module "auth0-deploy-ci-prod" {
  source = "./modules/ci"

  project_name      = "auth0-deploy"
  environment       = "prod"
  github_repo       = "https://github.com/mozilla-iam/auth0-deploy.git"
  github_head_ref   = "refs/heads/production"
  github_event_type = "PUSH"
  # For the time being, we don't want to autodeploy on merge
  enable_webhook = "false"
  enable_ecr     = "false"
  build_image    = "aws/codebuild/python:3.6.5"
  source_version = "production"
}

