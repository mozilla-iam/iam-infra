# Ark recommends to use one bucket per cluster
resource "aws_s3_bucket" "ark-bucket" {
  bucket = "ark-${var.environment}-${var.region}"
}

resource "aws_s3_bucket_acl" "ark-bucket" {
  bucket = aws_s3_bucket.ark-bucket.id
  acl = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ark-bucket" {
  bucket = aws_s3_bucket.ark-bucket.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.ark_kms_key.key_id
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_iam_role" "ark_role" {
  name = "ark-role-${var.environment}-${var.region}"

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

resource "aws_iam_role_policy" "ark_role_policy" {
  name = "ark-role-policy-${var.environment}-${var.region}"
  role = aws_iam_role.ark_role.id

  policy = <<EOF
{
     "Version": "2012-10-17",
     "Statement": [
         {
             "Effect": "Allow",
             "Action": [
                 "ec2:DescribeVolumes",
                 "ec2:DescribeSnapshots",
                 "ec2:CreateTags",
                 "ec2:CreateVolume",
                 "ec2:CreateSnapshot",
                 "ec2:DeleteSnapshot"
             ],
             "Resource": "*"
         },
         {
             "Effect": "Allow",
             "Action": [
                 "s3:GetObject",
                 "s3:DeleteObject",
                 "s3:PutObject",
                 "s3:AbortMultipartUpload",
                 "s3:ListMultipartUploadParts",
                 "s3:ListBucket"
             ],
             "Resource": [
                 "arn:aws:s3:::${aws_s3_bucket.ark-bucket.id}/*"
             ]
         },
         {
             "Effect": "Allow",
             "Action": [
                 "s3:ListBucket"
             ],
             "Resource": [
                 "arn:aws:s3:::${aws_s3_bucket.ark-bucket.id}"
             ]
         },
         {
             "Effect": "Allow",
             "Action": [
                 "kms:Encrypt",
                 "kms:Decrypt",
                 "kms:ListKeys",
                 "kms:ReEncrypt*",
                 "kms:ListAliases",
                 "kms:GenerateDataKey*",
                 "kms:DescribeKey"
             ],
             "Resource": [
                 "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/${aws_kms_key.ark_kms_key.key_id}"
             ]
         }
     ]
}
EOF

}

resource "aws_kms_key" "ark_kms_key" {
  description = "This key is used by ARK for encrypt/decrypt Kubernetes backups"
}

# This alias provides a name to the key. It will be displayed in the AWS console
resource "aws_kms_alias" "ark_kms_key_alias" {
  name          = "alias/ark-${var.environment}-${var.region}"
  target_key_id = aws_kms_key.ark_kms_key.key_id
}

