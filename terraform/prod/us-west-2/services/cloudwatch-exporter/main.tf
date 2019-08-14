#---
# Creates an IAM role with permissions to fetch Cloudwatch metrics
#---

resource "aws_iam_role" "cloudwatch_exporter_role" {
  name = "cloudwatch-exporter-${var.environment}"

  assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
     {
      "Effect": "Allow",
      "Principal": {
       "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
     },
     {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/kubernetes-prod-us-west-220181206181410238800000005"
       },
       "Action": "sts:AssumeRole"
      }
   ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch_exporter_role_policy" {
  name = "cloudwatch-exporter-policy-${var.environment}"
  role = "${aws_iam_role.cloudwatch_exporter_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:ListMetrics",
                "cloudwatch:GetMetricStatistics"
            ],
            "Resource": "*"
        }    
    ]
}
EOF
}
