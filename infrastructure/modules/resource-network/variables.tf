#
# Variables Configuration
#

variable "environment" {
    default = "development"
}

variable "region" {
    default = "us-west-2"
}

variable "vpc-main-rt-id" {}
variable "vpc-id" {}