#
# Outputs
#

locals {
  config-map-aws-auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.demo-node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH

}

output "config-map-aws-auth" {
  value = "${local.config-map-aws-auth}"
}

output "vpc-id" {
  value = "${aws_vpc.demo.id}"
}

output "vpc-main-rt-id" {
  value = "${aws_vpc.demo.main_route_table_id}"
}

output "node-security-group" {
  value = "${aws_security_group.demo-node.id}"
}
