output "iam_role_arn" {
  value       = aws_iam_role.cloudwatch_exporter_role.arn
  description = "ARN of the cloudwatch exporter Role"
}

