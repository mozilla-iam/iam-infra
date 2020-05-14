resource "aws_iam_policy_attachment" "attach_ssm_policy_to_ec2" {
  name       = "policy-for-ssm-stage"
  roles      = ["kubernetes-stage-us-west-220190207165215030100000005", "kubernetes-prod-us-west-220181206181410238800000005"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

