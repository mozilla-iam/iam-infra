#---
# Resource VPCs
# Shared resources like RDS and Elasticache reside here
#---

resource "aws_vpc" "resource-vpc" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags {
    "Name" = "apps-${var.environment}-${var.region}-vpc"
  }
}

#---
# Enable VPC peering between EKS VPC and resource VPC
#---

resource "aws_vpc_peering_connection" "resource-vpc" {
  peer_vpc_id = "${aws_vpc.resource-vpc.id}"
  vpc_id      = "${var.vpc-id}"
  auto_accept = true
}

#---
# Resource VPC subnets
# Currently scoped to us-west-2 region
#---

resource "aws_subnet" "resource-2a" {
  vpc_id                  = "${aws_vpc.resource-vpc.id}"
  cidr_block              = "172.16.0.0/18"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags {
    "Name" = "apps-${var.environment}-${var.region}-2a"
  }
}

resource "aws_subnet" "resource-2b" {
  vpc_id                  = "${aws_vpc.resource-vpc.id}"
  cidr_block              = "172.16.64.0/18"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true

  tags {
    "Name" = "apps-${var.environment}-${var.region}-2b"
  }
}

resource "aws_subnet" "resource-2c" {
  vpc_id                  = "${aws_vpc.resource-vpc.id}"
  cidr_block              = "172.16.128.0/18"
  availability_zone       = "us-west-2c"
  map_public_ip_on_launch = true

  tags {
    "Name" = "apps-${var.environment}-${var.region}-2c"
  }
}

#---
# Create internet gateway for resource VPC
#---

resource "aws_internet_gateway" "resource-igw" {
  vpc_id = "${aws_vpc.resource-vpc.id}"

  tags = {
    Name = "apps-${var.environment}-${var.region}-igw"
  }
}

#---
# Update VPC routes
# Enables communication between EKS and resource VPCs
#---

resource "aws_route" "eks-vpc-route" {
  route_table_id            = "${aws_vpc.resource-vpc.main_route_table_id}"
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.resource-vpc.id}"
}

resource "aws_route" "eks-ig-route" {
  route_table_id         = "${aws_vpc.resource-vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.resource-igw.id}"
}
