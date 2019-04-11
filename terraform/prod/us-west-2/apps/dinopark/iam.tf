#---
# IAM
#---

resource "aws_iam_role" "dinopark" {
  name = "dinopark-${var.environment}-${var.region}"

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

resource "aws_iam_role_policy" "ses" {
  name = "dinopark-${var.environment}-${var.region}-ses"
  role = "${aws_iam_role.dinopark.id}"

  policy = <<POLICY
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":[
            "ses:Get*",
            "ses:List*"
         ],
         "Resource":"*"
      }
   ]
}
POLICY
}

resource "aws_iam_role_policy" "s3" {
  name = "dinopark-${var.environment}-${var.region}s3"
  role = "${aws_iam_role.dinopark.id}"

  policy = <<POLICY
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":"s3:*",
         "Resource":[
            "${aws_s3_bucket.dinopark.arn}",
            "${aws_s3_bucket.dinopark.arn}/*",
            "${aws_s3_bucket.dinopark-exports.arn}",
            "${aws_s3_bucket.dinopark-exports.arn}/*",
            "${aws_s3_bucket.dinopark-orgchart.arn}",
            "${aws_s3_bucket.dinopark-orgchart.arn}/*"
         ]
      }
   ]
}
POLICY
}

resource "aws_iam_role_policy" "ssm" {
  name = "dinopark-${var.environment}-${var.region}-ssm"
  role = "${aws_iam_role.dinopark.id}"

  policy = <<POLICY
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":[
            "ssm:GetParameter*"
         ],
         "Resource":"arn:aws:ssm:us-west-2:${data.aws_caller_identity.current.account_id}:parameter/iam/dinopark/${var.environment}/${var.region}/*"
      },
      {
         "Effect":"Allow",
         "Action":[
            "kms:Decrypt"
         ],
         "Resource":"arn:aws:kms:us-west-2:${data.aws_caller_identity.current.account_id}:key/${data.aws_kms_key.ssm.id}"
      }
   ]
}
POLICY
}

#resource "aws_iam_role_policy" "cispublisher" {
#  name = "dinopark-${var.environment}-${var.region}-assume-cis-publisher"
#  role = "${aws_iam_role.dinopark.id}"
#
#  policy = <<POLICY
#{
#   "Version": "2012-10-17",
#   "Statement": [
#       {
#           "Sid": "",
#           "Effect": "Allow",
#           "Action": "sts:AssumeRole",
#           "Resource": "arn:aws:iam::656532927350:role/CISPublisherRole"
#       }
#   ]
#}
#POLICY
#}

