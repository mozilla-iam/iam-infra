resource "aws_route53_record" "dinopark" {
  zone_id = "${data.aws_route53_zone.sso_allizom_org.zone_id}"
  name    = "dinopark.k8s.dev.sso.allizom.org"
  type    = "A"

  alias {
    name                   = "dualstack.${data.aws_elb.k8s-elb.dns_name}"
    zone_id                = "${data.aws_elb.k8s-elb.zone_id}"
    evaluate_target_health = false
  }
}
