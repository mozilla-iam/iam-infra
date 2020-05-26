variable "region" {
  default = "us-west-2"
}

variable "environment" {
  default = "prod"
}

variable "ses-domain-test" {
  default = "dinopark.k8s.test.sso.allizom.org"
}

variable "ses-domain-prod" {
  default = "people.mozilla.org"
}
