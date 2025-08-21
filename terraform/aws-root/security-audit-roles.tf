data "aws_caller_identity" "current" {}
data "aws_organizations_organization" "default" {}

data "aws_organizations_organizational_unit_descendant_accounts" "accounts" {
  parent_id = data.aws_organizations_organization.default.roots[0].id
}

locals {
  child_account_list = [for ca in data.aws_organizations_organizational_unit_descendant_accounts.accounts.accounts: ca.id]
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
              PolicyName     = local.security_audit_role_name
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
              PolicyName     = local.security_audit_role_name
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
      identifiers = setunion(data.aws_iam_roles.admin_sso_roles.arns, data.aws_iam_roles.security_sso_roles.arns)
    }
  }
}

data "aws_iam_policy_document" "security_audit_assume_role_descendants" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.security_audit_role_name}"]
    }
  }
}

data "aws_iam_policy_document" "security_audit_descendants" {
  # Statement 1: These actions require Resources="*"
  statement {
    actions = [
      "dynamodb:ListTables",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ecs:ListClusters",
      "eks:ListClusters",
      "lambda:ListFunctions",
      "lightsail:GetInstances",
      "lightsail:GetRegions",
      "rds:DescribeDBClusters",
      "rds:DescribeDBInstances",
      "redshift:DescribeClusters",
      "s3:ListAllMyBuckets",
      "sagemaker:ListDomains",
      "sagemaker:ListEndpoints",
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }

  # Statement 2: Resource-scoped where supported
  statement {
    sid     = "AllowGeneralReadOnlyResourceScoped"
    actions = [
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecs:DescribeTasks",
      "ecs:ListContainerInstances",
      "ecs:ListTasks",
      "eks:ListFargateProfiles",
      "lambda:ListVersionsByFunction",
    ]
    resources = [
      "arn:aws:ecr:*:*:repository/*",          # ECR repos
      "arn:aws:ecs:*:*:cluster/*",             # ECS cluster (needed for ListContainerInstances)
      "arn:aws:ecs:*:*:container-instance/*",  # ECS container-instance (needed for ListTasks)
      "arn:aws:ecs:*:*:task/*",                # ECS tasks (DescribeTasks)
      "arn:aws:eks:*:*:cluster/*",             # EKS cluster (ListFargateProfiles)
      "arn:aws:lambda:*:*:function:*",         # Lambda function (ListVersionsByFunction)
    ]
  }
}

data "aws_iam_policy_document" "security_audit_root" {
  source_policy_documents = [data.aws_iam_policy_document.security_audit_descendants.json]
  statement {
    sid       = "AllowAssumeMozillaSecurityAudit"
    actions   = ["sts:AssumeRole"]
    resources = formatlist("arn:aws:iam::%s:role/%s", local.child_account_list, local.security_audit_role_name)
  }
  statement {
    sid = "AllowOrganizationRead"
    actions = [
      "organizations:DescribeOrganization",
      "organizations:ListAccounts",
    ]
    # Both actions require Resources="*"
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
  operation_preferences {
    max_concurrent_percentage = 33
  }

  # AWS returns an AdministrationRoleARN even in SERVICE_MANAGED.
  # Ignore it so plans stop showing an in-place update.
  lifecycle {
    ignore_changes = [administration_role_arn]
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
