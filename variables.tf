variable "account_name" {
  description = "The name of the AWS account to be created"
  type        = string
}

variable "account_email" {
  description = "The email for the AWS account"
  type        = string
}

variable "role_name" {
  description = "The role name for the new account"
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "organization_root_id" {
  description = "The organization root ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the new account"
  type        = map(string)
}

variable "password_policy" {
  description = "Password policy settings"
  type = object({
    minimum_password_length        = number
    require_uppercase_characters   = bool
    require_lowercase_characters   = bool
    require_numbers                = bool
    require_symbols                = bool
    allow_users_to_change_password = bool
    max_password_age               = number
  })
}

variable "power_user_actions" {
  description = "Actions allowed for the Power User policy"
  type        = list(string)
}

variable "custom_policy" {
  description = "Custom IAM policy settings"
  type = object({
    name        = string
    description = string
    policy      = string
  })
}

variable "users" {
  description = "List of users to create"
  type = map(object({
    name  = string
    email = string
    role  = string
  }))

  validation {
    condition = can(
      length([for user in values(var.users) : user if user.role == "Administrator"]) > 0
    )
    error_message = "At least one user must have the role 'Administrator'."
  }
}

variable "cloudtrail_bucket_name_prefix" {
  description = "The name of the S3 bucket for CloudTrail logs"
  type        = string
}

variable "config_bucket_name_prefix" {
  description = "The name of the S3 bucket for AWS Config"
  type        = string
}

variable "password_length" {
  description = "Length of the user passwords"
  type        = number
  default     = 16
}

variable "group_name" {
  description = "Name of the IAM group"
  type        = string
}

variable "group_policy_arns" {
  description = "List of policy ARNs to attach to the group"
  type        = list(string)
}

variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "provider_alias" {
  description = "Alias for the subaccount provider"
  type        = string
  default     = "subaccount"
}