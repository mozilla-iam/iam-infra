resource "aws_route53_record" "graylog" {
  zone_id = data.aws_route53_zone.infra_iam.zone_id
  name    = "graylog.infra.iam.mozilla.com"
  type    = "A"

  alias {
    name                   = "dualstack.${data.aws_elb.k8s-elb.dns_name}"
    zone_id                = data.aws_elb.k8s-elb.zone_id
    evaluate_target_health = false
  }
}

