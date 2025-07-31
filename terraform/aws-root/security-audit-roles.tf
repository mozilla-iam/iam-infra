data "aws_caller_identity" "current" {}
data "aws_organizations_organization" "default" {}

locals {
  security_audit_role_name = "MozillaSecurityAudit"
  security_audit_role_cloudformation_root = {
    Resources = {
      AuditRole = {
        Type = "AWS::IAM::Role"
        Properties = {
          RoleName                 = local.security_audit_role_name
          Description              = "For Security to use for auditing (IAM-1476)."
          AssumeRolePolicyDocument = data.aws_iam_policy_document.security_audit_assume_role_root.json
          Policies = [
            {
              PolicyName     = "MozillaSecurityAudit"
              PolicyDocument = data.aws_iam_policy_document.security_audit_root.json
            }
          ]
          Tags = [
            { Key = "Managed-By", Value = "Terraform" },
            { Key = "Owner", Value = "IAM" }
          ]
        }
      }
    }
  }
  security_audit_role_cloudformation_descendants = {
    Resources = {
      AuditRole = {
        Type = "AWS::IAM::Role"
        Properties = {
          RoleName                 = local.security_audit_role_name
          Description              = "For Security to use for auditing (IAM-1476)."
          AssumeRolePolicyDocument = data.aws_iam_policy_document.security_audit_assume_role_descendants.json
          Policies = [
            {
              PolicyName     = "MozillaSecurityAudit"
              PolicyDocument = data.aws_iam_policy_document.security_audit_descendants.json
            }
          ]
          Tags = [
            { Key = "Managed-By", Value = "Terraform" },
            { Key = "Owner", Value = "IAM" }
          ]
        }
      }
    }
  }
}

data "aws_iam_roles" "security_sso_roles" {
  name_regex  = "AWSReservedSSO_MAWS-OrgSecurityAuditor_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "admin_sso_roles" {
  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_policy_document" "security_audit_assume_role_root" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"
      values = setunion(
        data.aws_iam_roles.admin_sso_roles.arns,
        data.aws_iam_roles.security_sso_roles.arns,
      )
    }
  }
}

data "aws_iam_policy_document" "security_audit_assume_role_descendants" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.security_audit_role_name}"]
    }
  }
}

data "aws_iam_policy_document" "security_audit_descendants" {
  statement {
    sid = "AllowGeneralReadOnly"
    actions = [
      "dynamodb:ListTables",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeRepositories",
      "ecr:ListImages",
      "ecr:ListImages",
      "ecs:DescribeTasks",
      "ecs:ListClusters",
      "ecs:ListContainerInstances",
      "ecs:ListTasks",
      "eks:ListClusters",
      "eks:ListFargateProfiles",
      "lambda:ListFunctions",
      "lambda:ListVersionsByFunction",
      "lightsail:GetInstances",
      "lightsail:GetRegions",
      "rds:DescribeDBClusters",
      "rds:DescribeDBInstances",
      "redshift:DescribeClusters",
      "s3:ListAllMyBuckets",
      "s3:ListBuckets",
      "sagemaker:ListDomains",
      "sagemaker:ListEndpoints",
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "security_audit_root" {
  source_policy_documents = [data.aws_iam_policy_document.security_audit_descendants.json]
  statement {
    sid       = "AllowAssumeMozillaSecurityAudit"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::*:role/${local.security_audit_role_name}"]
  }
  statement {
    sid = "AllowOrganizationRead"
    actions = [
      "organizations:DescribeOrganization",
      "organizations:ListAccounts",
    ]
    resources = ["*"]
  }
}

resource "aws_cloudformation_stack_set" "security_audit_descendants" {
  name             = "security-audit-role"
  template_body    = jsonencode(local.security_audit_role_cloudformation_descendants)
  capabilities     = ["CAPABILITY_NAMED_IAM"]
  permission_model = "SERVICE_MANAGED"
  auto_deployment {
    enabled = true
  }
}

resource "aws_cloudformation_stack_instances" "security_audit_descendants" {
  stack_set_name = aws_cloudformation_stack_set.security_audit_descendants.name
  deployment_targets {
    organizational_unit_ids = [data.aws_organizations_organization.default.roots[0].id]
  }
}

# Since StackSets don't deploy to the management account, we have to do it
# ourselves.
# See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_instances#deployment_targets-1
resource "aws_cloudformation_stack" "security_audit" {
  name          = "security-audit-role"
  capabilities  = ["CAPABILITY_NAMED_IAM"]
  template_body = jsonencode(local.security_audit_role_cloudformation_root)
}
