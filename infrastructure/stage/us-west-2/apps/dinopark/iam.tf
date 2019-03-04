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
