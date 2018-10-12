#---
# Create CI pipeline:
#   - CodeBuild and ECR
#   - Uses OAuth to create webhooks in GitHub repositories
#
# https://docs.aws.amazon.com/codepipeline/latest/userguide/GitHub-authentication.html
#---

module "sso-dashboard-ci-stage" {
  source = "./modules/ci"

  project_name   = "sso-dashboard"
  environment    = "stage"
  github_repo    = "https://github.com/mozilla-iam/sso-dashboard"
  github_branch  = "^master$"
  enable_webhook = "true"
}

module "sso-dashboard-ci-prod" {
  source = "./modules/ci"

  project_name   = "sso-dashboard"
  environment    = "prod"
  github_repo    = "https://github.com/mozilla-iam/sso-dashboard"
  github_branch  = "^production$"
  enable_webhook = "true"
}
