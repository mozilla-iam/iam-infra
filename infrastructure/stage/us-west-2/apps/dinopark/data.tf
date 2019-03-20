data "aws_caller_identity" "current" {}

data "aws_route53_zone" "sso_allizom_org" {
  name = "sso.allizom.org."
}

data "aws_elb" "k8s-elb" {
  name = "a7a24df442f7b11e99b430a9340ca296"
}
