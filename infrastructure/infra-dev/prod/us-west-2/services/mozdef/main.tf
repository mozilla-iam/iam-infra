resource "aws_sqs_queue" "logs2mozdef" {
  name = "logs2MozDef"
}

resource "aws_sqs_queue_policy" "allowSNS" {
  queue_url = "${aws_sqs_queue.logs2mozdef.id}"
 
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "AllowSNStoSQSForMozDef",
  "Statement": [
    {
      "Sid": "AllowSNStoPublish",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.logs2mozdef.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn":  "${aws_sns_topic.logs2mozdef.arn}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_sns_topic" "logs2mozdef" {
  name = "logs2MozDef"
}

resource "aws_sns_topic_subscription" "logs2mozdef" {
  topic_arn = "${aws_sns_topic.logs2mozdef.arn}"
  protocol  = "sqs"
  endpoint  = "${aws_sqs_queue.logs2mozdef.arn}"
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

resource "aws_iam_role_policy" "fluentd_mozdef_role_policy" {
  name = "fluentd-mozdef-policy-${var.environment}-${var.region}"
  role = "${aws_iam_role.fluentd_mozdef_role.id}"

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

