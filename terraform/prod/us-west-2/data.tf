data "aws_availability_zones" "available" {
}

data "aws_caller_identity" "current" {
}

data "aws_route53_zone" "infra_iam" {
  name = "infra.iam.mozilla.com."
}

data "aws_route53_zone" "sso_mozilla_com" {
  name = "sso.mozilla.com."
}

data "aws_route53_zone" "sso_allizom_org" {
  name = "sso.allizom.org."
}

data "aws_route53_zone" "people_mozilla_org" {
  name = "people.mozilla.org."
}

data "aws_elb" "k8s-elb" {
  name = "a00435690f99111e8989b0ace417809a"
}

data "aws_security_group" "es-allow-https" {
  id = "sg-08f1fb74db97a268e"
}

data "aws_elb" "dinopark-test-elb" {
  name = "a8cd8ab927d3211e9976f06f807dee91"
}

data "aws_elb" "dinopark-prod-elb" {
  name = "af3ef016b807c11e9976f06f807dee91"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
