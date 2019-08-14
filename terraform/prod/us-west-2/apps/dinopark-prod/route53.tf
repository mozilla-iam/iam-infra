resource "aws_route53_record" "dinopark" {
  zone_id = data.aws_route53_zone.sso_mozilla_com.zone_id
  name    = "dinopark.k8s.sso.mozilla.com"
  type    = "A"

  alias {
    name                   = "dualstack.${data.aws_elb.k8s-elb.dns_name}"
    zone_id                = data.aws_elb.k8s-elb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "picture_api" {
  zone_id = data.aws_route53_zone.sso_mozilla_com.zone_id
  name    = "picture.api.sso.mozilla.com"
  type    = "A"

  alias {
    name                   = "dualstack.${data.aws_elb.k8s-elb.dns_name}"
    zone_id                = data.aws_elb.k8s-elb.zone_id
    evaluate_target_health = false
  }
}

