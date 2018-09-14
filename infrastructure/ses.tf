module "ses" {
  source  = "./modules/ses"
  domain  = "alerts.iam.mozilla.com"
  zone_id = "..."
}
