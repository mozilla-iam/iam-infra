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
  route_table_id         = "${aws_vpc.demo.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.demo.id}"
}

resource "aws_route" "resource-vpc-route" {
  count                     = "${var.create-resource-vpc ? 1 : 0}"
  route_table_id            = "${aws_vpc.demo.main_route_table_id}"
  destination_cidr_block    = "172.16.0.0/16"
  vpc_peering_connection_id = "${var.peering-connection-id}"
}
