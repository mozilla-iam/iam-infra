resource "aws_iam_role" "dinopark_fence_role" {
  name = "dinopark-fence-role-${var.environment}-${var.region}"

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
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/kubernetes-stage-us-west-220190207165215030100000005"
       },
       "Action": "sts:AssumeRole"
      }
   ]
}
EOF
}

resource "aws_iam_role_policy" "cis-secret-retrieval" {
  name        = "cis-secret-retrieval-${var.environment}-${var.region}"
  role        = "${aws_iam_role.dinopark_fence_role.id}"

  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
         "ssm:GetParameterHistory",
         "ssm:GetParametersByPath",
         "ssm:GetParameters",
         "ssm:GetParameter"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:ssm:*:*:parameter/iam/cis/development/*"
      ]
    },
    {
      "Action": [
         "kms:Decrypt"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:kms:us-west-2:320464205386:key/ef00015d-739b-456d-a92f-482712af4f32"
      ]
    }
  ]
}
EOF
}

# Deprecated: delete me once we are sure pods are using the correct role
resource "aws_iam_policy" "cis-development-secret-retrieval" {
  name        = "cis-development-secret-retrieval"
  path        = "/"
  description = "Allows retrieval of secrets in the cis_development namespace."

  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
         "ssm:GetParameterHistory",
         "ssm:GetParametersByPath",
         "ssm:GetParameters",
         "ssm:GetParameter"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:ssm:*:*:parameter/iam/cis/development/*"
      ]
    },
    {
      "Action": [
         "kms:Decrypt"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:kms:us-west-2:320464205386:key/ef00015d-739b-456d-a92f-482712af4f32"
      ]
    }
  ]
}
EOF
}

