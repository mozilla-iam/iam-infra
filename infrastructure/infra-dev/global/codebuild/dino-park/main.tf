module "dino-park-front-end-ci" {
  source       = "./modules/sites/dino-park-front-end"
  service_name = "dino-park-front-end"
}

module "dino-tree-ci" {
  source       = "./modules/sites/dino-tree"
  service_name = "dino-tree"
}

module "dino-park-search-ci" {
  source       = "./modules/sites/dino-park-search"
  service_name = "dino-park-search"
}

module "dino-park-mozillians-ci" {
  source       = "./modules/sites/dino-park-mozillians"
  service_name = "dino-park-mozillians"
}
