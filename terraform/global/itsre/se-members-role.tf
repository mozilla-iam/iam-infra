module "it_se_role" {
  source       = "github.com/mozilla-it/terraform-modules//aws/maws-roles?ref=master"
  role_name    = "it-se-maws"
  role_mapping = ["team_se"]
  policy_arn   = aws_iam_policy.it_se.arn
}

resource "aws_iam_policy" "it_se" {
  name   = "ITSETeamPolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.it_se.json
}

data "aws_iam_policy_document" "it_se" {

  statement {
    sid       = "eksAccess"
    actions   = ["eks:*"]
    resources = ["arn:aws:eks:us-west-2::*"]
  }

  statement {
    sid       = "s3ListBuckets"
    resources = ["arn:aws:s3:::*"]
    actions   = ["s3:ListAllMyBuckets", "s3:ListBucket"]
  }

  statement {
    sid       = "ec2Access"
    resources = ["arn:aws:ec2:us-west-2::*"]
    actions   = ["ec2:*"]
  }

  statement {
    sid       = "route53Access"
    resources = ["arn:aws:route53:::*"]
    actions   = ["route53:*"]
  }

  statement {
    sid       = "RDSAccess"
    resources = ["arn:aws:rds:us-west-2::*"]
    actions   = ["rds:*"]
  }

  statement {
    sid       = "elasticsearchAccess"
    resources = ["arn:aws:es:us-west-2::*"]
    actions   = ["es:*"]
  }

  statement {
    sid       = "CloudFrontAccess"
    resources = ["arn:aws:cloudfront:::*"]
    actions   = ["cloudfront:*"]
  }

  statement {
    sid       = "CloudWatchAccess"
    resources = ["arn:aws:logs:::dino*"]
    actions   = ["logs:*"]
  }
}

