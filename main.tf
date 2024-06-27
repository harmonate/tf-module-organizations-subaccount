resource "aws_organizations_account" "subaccount" {
  name      = var.account_name
  email     = var.account_email
  role_name = var.role_name
  parent_id = var.organization_root_id
  tags = var.tags
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
    effect = "Allow"
    actions = var.power_user_actions
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
