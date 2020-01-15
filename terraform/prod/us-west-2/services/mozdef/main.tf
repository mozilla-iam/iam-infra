resource "aws_sns_topic" "logs2mozdef" {
  name = "logs2MozDef"
}

# This topic policy allows InfoSec account to manage the topic
# and consume its messages via SQS.
resource "aws_sns_topic_policy" "allowInfosecAccount" {
  arn = aws_sns_topic.logs2mozdef.arn

  policy = <<EOF
{
    "Version":"2012-10-17",
    "Id": "__default_policy_ID",
    "Statement":[
        {
            "Principal": {
                "AWS": "*"
            },
            "Effect": "Allow",
            "Action": [
                "SNS:Publish",
                "SNS:RemovePermission",
                "SNS:SetTopicAttributes",
                "SNS:DeleteTopic",
                "SNS:ListSubscriptionsByTopic",
                "SNS:GetTopicAttributes",
                "SNS:Receive",
                "SNS:AddPermission",
                "SNS:Subscribe"
            ],
            "Resource": "${aws_sns_topic.logs2mozdef.arn}",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceOwner": "320464205386"
                }
            },
            "Sid": "Allow_Infosec_to_manage_topic"
        },
        {
            "Principal": {
                "AWS": "arn:aws:iam::371522382791:root"
            },
            "Effect": "Allow",
            "Action": [
                "SNS:Subscribe",
                "SNS:Receive"
            ],
            "Resource": "${aws_sns_topic.logs2mozdef.arn}",
            "Condition": {
                "StringEquals": {
                    "SNS:Protocol": "sqs"
                }
            },
            "Sid": "Allow_InfoSec_consume_via_SQS"
        }
    ]
}
EOF

}

# This IAM role allows FluentD (assuming the role) to publish
# to the SNS topic.
resource "aws_iam_role_policy" "fluentd_mozdef_role_policy" {
  name = "fluentd-mozdef-policy-${var.environment}-${var.region}"
  role = aws_iam_role.fluentd_mozdef_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "SNS:ListTopics"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "SNS:Publish"
            ],
            "Resource": [
                "${aws_sns_topic.logs2mozdef.arn}"
            ]
        }
    ]
}
EOF

}

resource "aws_iam_role" "fluentd_mozdef_role" {
  name = "fluentd-mozdef-${var.environment}-${var.region}"

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

