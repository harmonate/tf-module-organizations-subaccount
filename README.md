# tf-module-organizations-subaccount

```hcl
module "subaccount" {
  source = "git::https://github.com/harmonate/tf-module-organizations-subaccount.git?ref=main"

  account_name        = "NewAccount"
  account_email       = "newaccount@example.com"
  role_name           = "OrganizationAccountAccessRole"
  organization_root_id = "r-xxxx"
  tags = {
    Environment = "Development"
  }
  password_policy = {
    minimum_password_length        = 12
    require_uppercase_characters   = true
    require_lowercase_characters   = true
    require_numbers                = true
    require_symbols                = true
    allow_users_to_change_password = true
    max_password_age               = 90
  }
  power_user_actions = [
    "ec2:*",
    "s3:*",
    "iam:*"
  ]
  custom_policy = {
    name        = "CustomPolicy"
    description = "A custom policy"
    policy      = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "cloudtrail:GetTrailStatus",
            "cloudtrail:LookupEvents"
          ],
          Resource = "*"
        }
      ]
    })
  }
  users = {
    "john_doe" = {
      name  = "john_doe"
      email = "john_doe+extension@example.com"
      role  = "Administrator"
    },
    "jane_doe" = {
      name  = "jane_doe"
      email = "jane_doe@example.com"
      role  = "Developers"
    }
  }
  password_length = 16
  group_name      = "Developers"
  group_policy_arns = [
    "arn:aws:iam::aws:policy/PowerUserAccess"
  ]
  region = "us-east-1"
  cloudtrail_bucket_name_prefix     = "my-cloudtrail-bucket"
  config_bucket_name_prefix         = "my-config-bucket"
}
```
