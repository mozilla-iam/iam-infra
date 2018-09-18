output "vpc-main-rt-id" {
  value = "${aws_vpc.resource-vpc.main_route_table_id}"
}

output "peering-connection-id" {
  value = "${aws_vpc_peering_connection.resource-vpc.id}"
}

output "vpc-id" {
  value = "${aws_vpc.resource-vpc.id}"
}
