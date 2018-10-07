#---
# Create CI pipeline:
#   - CodeBuild and ECR
#   - Uses OAuth to create webhooks in GitHub repositories
#
# https://docs.aws.amazon.com/codepipeline/latest/userguide/GitHub-authentication.html
#---

module "auth0-deploy-ci-stage" {
  source = "./modules/ci"

  project_name   = "auth0-deploy"
  environment    = "stage"
  github_repo    = "https://github.com/mozilla-iam/auth0-deploy"
  github_branch  = "master"
  enable_webhook = "true"
  enable_ecr     = "false"
  build_image    = "aws/codebuild/python:3.6.5"
}

