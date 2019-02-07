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
  
