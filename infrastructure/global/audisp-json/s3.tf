resource "aws_s3_bucket" "audisp-json" {
  bucket = "audisp-json"
  acl    = "private"

  tags {
    Name   = "audisp-json"
  }
}

resource "aws_s3_bucket_policy" "allow_account_ro" {
  bucket = "${aws_s3_bucket.audisp-json.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "Allow everyone to get these objects",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { 
        "AWS": "*"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::audisp-json/*"
    }
  ]
}
POLICY
}
