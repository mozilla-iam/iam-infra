#
# Variables Configuration
#

variable "cluster-name" {
  type = "string"
}

variable "instance-type" {
  type    = "string"
  default = "c4.large"
}

variable "instance-desired-capacity" {
  default = 3
}

variable "instance-min" {
  default = 2
}

variable "instance-max" {
  default = 3
}

variable "create-resource-vpc" {
  default = false
}

variable "environment" {
  default = "development"
}

variable "region" {
  default = "us-west-2"
}

variable "peering-connection-id" {
  default = "unused"
}
