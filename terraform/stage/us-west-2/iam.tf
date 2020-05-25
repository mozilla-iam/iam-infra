#---
# Provides a role for the cluster-autoscaler
#
# Note that the resource spec will result in a failure if we have
# multiple ASGs. I would like to find a way to successfully pass
# in a list.
#---

resource "aws_iam_role" "cluster_autoscaler" {
  name = "cluster-autoscaler-${var.environment}-${var.region}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "${module.eks.worker_iam_role_arn}"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "cluster_autoscaler" {
  name = "cluster-autoscaler-${var.environment}-${var.region}"
  role = aws_iam_role.cluster_autoscaler.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "autoscaling:DescribeLaunchConfigurations"
            ],
            "Resource": "*"
        }
    ]
}
EOF

}
