resource "aws_iam_policy_attachment" "attach_ssm_policy_to_ec2" {
  name       = "policy-for-ssm-prod"
  roles      = ["kubernetes-prod-us-west-220181206181410238800000005"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}
