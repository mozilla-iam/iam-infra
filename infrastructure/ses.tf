data "aws_route53_zone" "iam-mozilla" {
  name         = "iam.mozilla.com."
}

module "ses" {
  source  = "./modules/ses"
  domain  = "ops.iam.mozilla.com"
  zone_id = "${data.aws_route53_zone.iam-mozilla.zone_id}"
}
