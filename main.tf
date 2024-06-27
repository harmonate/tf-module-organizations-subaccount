resource "aws_organizations_account" "subaccount" {
  name      = var.account_name
  email     = var.account_email
  role_name = var.role_name
  parent_id = var.organization_root_id
  tags      = var.tags
}

resource "aws_iam_account_password_policy" "password_policy" {
  provider                       = aws.subaccount
  minimum_password_length        = var.password_policy.minimum_password_length
  require_uppercase_characters   = var.password_policy.require_uppercase_characters
  require_lowercase_characters   = var.password_policy.require_lowercase_characters
  require_numbers                = var.password_policy.require_numbers
  require_symbols                = var.password_policy.require_symbols
  allow_users_to_change_password = var.password_policy.allow_users_to_change_password
  max_password_age               = var.password_policy.max_password_age
}

data "aws_iam_policy_document" "power_user" {
  statement {
    effect    = "Allow"
    actions   = var.power_user_actions
    resources = ["*"]
  }
}

resource "aws_iam_policy" "power_user_policy" {
  provider = aws.subaccount
  name     = "PowerUserAccess"
  policy   = data.aws_iam_policy_document.power_user.json
}

resource "aws_iam_policy" "custom_policy" {
  provider    = aws.subaccount
  name        = var.custom_policy.name
  description = var.custom_policy.description
  policy      = var.custom_policy.policy
}

resource "aws_iam_user" "users" {
  for_each = var.users
  provider = aws.subaccount
  name     = each.value.name
  tags = {
    Email = each.value.email
    Role  = each.value.role
  }
}

resource "aws_iam_user_login_profile" "users" {
  for_each                = aws_iam_user.users
  provider                = aws.subaccount
  user                    = each.value.name
  password_length         = var.password_length
  password_reset_required = true
}

resource "aws_iam_group" "admin" {
  provider = aws.subaccount
  name     = "admin"
}

resource "aws_iam_group_policy_attachment" "admin_policy_attachment" {
  provider   = aws.subaccount
  group      = aws_iam_group.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_membership" "admin_membership" {
  provider = aws.subaccount
  name     = "admin_membership"
  users    = [for user, details in var.users : user if details.role == "Administrator"]
  group    = aws_iam_group.admin.name
}

resource "aws_iam_group" "group" {
  provider = aws.subaccount
  name     = var.group_name
}

resource "aws_iam_group_policy_attachment" "policies" {
  for_each   = toset(var.group_policy_arns)
  provider   = aws.subaccount
  group      = aws_iam_group.group.name
  policy_arn = each.value
}

resource "aws_iam_group_membership" "group_membership" {
  provider = aws.subaccount
  name     = "${var.group_name}_membership"
  users    = [for user in aws_iam_user.users : user.name]
  group    = aws_iam_group.group.name
}

resource "aws_iam_group_policy_attachment" "self_management_policy_attachment" {
  for_each   = toset([aws_iam_group.admin.name, var.group_name])
  provider   = aws.subaccount
  group      = each.value
  policy_arn = aws_iam_policy.self_management_policy.arn
}

data "aws_iam_policy_document" "self_management_policy" {
  statement {
    actions = [
      "iam:ChangePassword",
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:ResyncMFADevice",
      "iam:DeactivateMFADevice",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ListAccountAliases",
      "iam:ListUsers"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:iam::*:user/$${aws:username}",
      "arn:aws:iam::*:mfa/$${aws:username}"
    ]
  }
}

resource "aws_iam_policy" "self_management_policy" {
  provider = aws.subaccount
  name     = "SelfManagementPolicy"
  policy   = data.aws_iam_policy_document.self_management_policy.json
}

data "aws_iam_policy_document" "mfa_enforce_policy" {
  statement {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

resource "aws_iam_policy" "mfa_enforce_policy" {
  provider = aws.subaccount
  name     = "MFAEnforcePolicy"
  policy   = data.aws_iam_policy_document.mfa_enforce_policy.json
}

resource "aws_cloudtrail" "subaccount_trail" {
  depends_on                    = [aws_s3_bucket.cloudtrail_bucket]
  provider                      = aws.subaccount
  name                          = "${var.account_name}-trail"
  s3_bucket_name                = local.cloudtrail_bucket_name
  include_global_service_events = true
  is_multi_region_trail         = true
}

resource "aws_iam_role" "config_role" {
  provider = aws.subaccount
  name     = "AWSConfigRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config_role_policy" {
  provider   = aws.subaccount
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

resource "aws_config_configuration_recorder" "all" {
  provider = aws.subaccount
  name     = "all"
  role_arn = aws_iam_role.config_role.arn

  depends_on = [
    aws_iam_role_policy_attachment.config_role_policy,
    aws_config_delivery_channel.all
  ]
}

resource "aws_config_configuration_recorder_status" "all" {
  provider   = aws.subaccount
  name       = aws_config_configuration_recorder.all.name
  is_enabled = true

  depends_on = [
    aws_config_configuration_recorder.all
  ]
}

resource "aws_config_delivery_channel" "all" {
  provider       = aws.subaccount
  name           = "all"
  s3_bucket_name = local.config_bucket_name
  depends_on = [
    aws_s3_bucket.config_bucket,
    aws_s3_bucket_policy.config_bucket_policy
  ]
}
