provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "subaccount"
  region = var.region
  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.subaccount.id}:role/OrganizationAccountAccessRole"
  }
}
