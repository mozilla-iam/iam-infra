data "aws_caller_identity" "current" {
}

data "aws_route53_zone" "sso_allizom_org" {
  name = "sso.allizom.org."
}

data "aws_elb" "k8s-elb" {
  name = "aed7f2f217bc811e9bfc4029580efe58"
}

