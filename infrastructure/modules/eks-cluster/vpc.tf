#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

data "aws_region" "current" {}
data "aws_availability_zones" "available" {}

resource "aws_vpc" "demo" {
  cidr_block = "10.0.0.0/16"

  tags = "${
    map(
     "Name", "terraform-${var.cluster-name}-node",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_subnet" "demo" {
  count = 2

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = "${aws_vpc.demo.id}"

  tags = "${
    map(
     "Name", "terraform-${var.cluster-name}-node",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_internet_gateway" "demo" {
  vpc_id = "${aws_vpc.demo.id}"

  tags {
    Name = "terraform-${var.cluster-name}"
  }
}

resource "aws_route" "demo-route" {
  route_table_id            = "${aws_vpc.demo.main_route_table_id}"
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.demo.id}"
}

#---
# Create optional resource VPC and dependencies
#---

resource "aws_vpc" "resource-vpc" {
  count = "${var.create-resource-vpc ? 1 : 0}"
  cidr_block           = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags {
    "Name" = "apps-${var.cluster-name}-vpc"
  }  
}

#---
# Enable VPC peering between EKS VPC and resource VPC
#---

resource "aws_vpc_peering_connection" "resource-vpc" {
  count = "${var.create-resource-vpc ? 1 : 0}"
  peer_vpc_id = "${aws_vpc.resource-vpc.id}"
  vpc_id      = "${aws_vpc.demo.id}"
  auto_accept = true
}

#---
# Resource VPC subnets
# Currently scoped to us-west-2 region
#---

resource "aws_subnet" "resource-2a" {
  count = "${var.create-resource-vpc ? 1 : 0}"
  vpc_id                  = "${aws_vpc.resource-vpc.id}"
  cidr_block              = "172.16.0.0/18"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags {
    "Name" = "apps-${var.cluster-name}-2a"
  }
}

resource "aws_subnet" "resource-2b" {
  count = "${var.create-resource-vpc ? 1 : 0}"
  vpc_id                  = "${aws_vpc.resource-vpc.id}"
  cidr_block              = "172.16.64.0/18"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true

  tags {
    "Name" = "apps-${var.cluster-name}-2b"
  }
}

resource "aws_subnet" "resource-2c" {
  count = "${var.create-resource-vpc ? 1 : 0}"
  vpc_id                  = "${aws_vpc.resource-vpc.id}"
  cidr_block              = "172.16.128.0/18"
  availability_zone       = "us-west-2c"
  map_public_ip_on_launch = true

  tags {
    "Name" = "apps-${var.cluster-name}-2c"
  }
}

#---
# Create internet gateway for resource VPC
#---

resource "aws_internet_gateway" "resource-igw" {
  count = "${var.create-resource-vpc ? 1 : 0}"
  vpc_id = "${aws_vpc.resource-vpc.id}"

  tags = {
    Name = "apps-${var.cluster-name}-igw"
  }
}

#---
# Update VPC routes
# Enables communication between EKS and resource VPCs
#---

resource "aws_route" "eks-vpc-route" {
  count = "${var.create-resource-vpc ? 1 : 0}"
  route_table_id            = "${aws_vpc.resource-vpc.main_route_table_id}"
  destination_cidr_block    = "${aws_vpc.demo.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.resource-vpc.id}"
}

resource "aws_route" "eks-ig-route" {
  count = "${var.create-resource-vpc ? 1 : 0}"
  route_table_id            = "${aws_vpc.resource-vpc.main_route_table_id}"
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = "${aws_internet_gateway.resource-igw.id}"
}

resource "aws_route" "resource-vpc-route" {
  count = "${var.create-resource-vpc ? 1 : 0}"
  route_table_id            = "${aws_vpc.demo.main_route_table_id}"
  destination_cidr_block    = "${aws_vpc.resource-vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.resource-vpc.id}"
}
