output "new_account_id" {
  value = aws_organizations_account.subaccount.id
}

output "iam_user_console_login" {
  value = "https://${aws_organizations_account.subaccount.id}.signin.aws.amazon.com/console"
}

output "user_login_profiles" {
  value = {
    for user in aws_iam_user_login_profile.users : user.user => user.password
  }
}
