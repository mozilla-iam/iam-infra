resource "aws_iam_role" "grafanaCloudwatch" {
  name = "grafanaCloudwatch"

  assume_role_policy = <<POLICY
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Action":"sts:AssumeRole",
         "Principal":{
            "AWS":"arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/terraform-kubernetes-production-01-node"
         },
         "Effect":"Allow",
         "Sid":""
      }
   ]
}
POLICY
}

resource "aws_iam_role_policy" "grafana_cloudwatch_metrics" {
  name = "grafana_cloudwatch_metrics"
  role = "${aws_iam_role.grafana.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowReadingMetricsFromCloudWatch",
      "Effect": "Allow",
      "Action": [
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowReadingTagsInstancesRegionsFromEC2",
      "Effect": "Allow",
      "Action": [
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

