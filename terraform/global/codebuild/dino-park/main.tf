module "dino-park-front-end-ci" {
  source       = "./modules/sites/dino-park-front-end"
  service_name = "dino-park-front-end"
}

module "dino-park-mozillians-ci" {
  source       = "./modules/sites/dino-park-mozillians"
  service_name = "dino-park-mozillians"
}
