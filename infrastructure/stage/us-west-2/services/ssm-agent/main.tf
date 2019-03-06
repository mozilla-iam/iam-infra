resource "aws_iam_policy_attachment" "attach_ssm_policy_to_ec2" {
  name       = "policy-for-ssm-stage"
  roles      = ["kubernetes-stage-us-west-220190207165215030100000005"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

