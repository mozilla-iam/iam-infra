resource "aws_sns_topic" "iamlogs2mozdef" {
  name = "IAMlogs2MozDef"
}

resource "aws_sns_topic_policy" "iamlogs2mozdef" {
  arn    = "${aws_sns_topic.iamlogs2mozdef.arn}"
  policy = "${data.aws_iam_policy_document.iamlogs2mozdef.json}"
}

data "aws_iam_policy_document" "iamlogs2mozdef" {
  policy_id = "AllowMozDefToSubscribe"
  statement {
    actions   = [ "sns:Subscribe" ]
    effect    = "Allow"
    principals {
      type        = "AWS"
      identifiers = [ "371522382791" ]
    }
    resources = [ "${aws_sns_topic.iamlogs2mozdef.arn}" ]
    sid = "AllowMozDefToSubscribe"
  }
}
