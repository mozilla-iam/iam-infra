module "mozillians-staging-ci" {
  source       = "./modules/sites/mozillians-staging"
  service_name = "mozillians-staging"
}

module "mozillians-production-ci" {
  source       = "./modules/sites/mozillians-prod"
  service_name = "mozillians-production"
}
