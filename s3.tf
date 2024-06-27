resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
  lower   = true
}


locals {
  config_bucket_name     = "${var.config_bucket_name_prefix}-${random_string.suffix.result}"
  cloudtrail_bucket_name = "${var.cloudtrail_bucket_name_prefix}-${random_string.suffix.result}"
}

# Conditional data source for existing config bucket
data "aws_s3_bucket" "existing_config_bucket" {
  bucket = local.config_bucket_name
}

# Conditional data source for existing cloudtrail bucket
data "aws_s3_bucket" "existing_cloudtrail_bucket" {
  bucket = local.cloudtrail_bucket_name
}

resource "aws_s3_bucket" "config_bucket" {
  count         = length([for k, v in data.aws_s3_bucket.existing_config_bucket : k]) == 0 ? 1 : 0
  bucket        = local.config_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "config_bucket_ownership" {
  count  = length(aws_s3_bucket.config_bucket)
  bucket = aws_s3_bucket.config_bucket[count.index].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "config_bucket_acl" {
  count      = length(aws_s3_bucket.config_bucket)
  depends_on = [aws_s3_bucket_ownership_controls.config_bucket_ownership]

  bucket = aws_s3_bucket.config_bucket[count.index].id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "config_bucket_versioning" {
  count  = length(aws_s3_bucket.config_bucket)
  bucket = aws_s3_bucket.config_bucket[count.index].id
  versioning_configuration {
    status = "Disabled"
  }
  mfa = "Disabled"
}

resource "aws_s3_bucket_lifecycle_configuration" "config_bucket_lifecycle" {

  provider = aws.subaccount
  count    = length(aws_s3_bucket.config_bucket)
  bucket   = aws_s3_bucket.config_bucket[count.index].id

  rule {
    id     = "config-lifecycle-rule"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket" "cloudtrail_bucket" {
  count         = length([for k, v in data.aws_s3_bucket.existing_cloudtrail_bucket : k]) == 0 ? 1 : 0
  bucket        = local.cloudtrail_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "cloudtrail_bucket_ownership" {
  count  = length(aws_s3_bucket.cloudtrail_bucket)
  bucket = aws_s3_bucket.cloudtrail_bucket[count.index].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloudtrail_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.cloudtrail_bucket_ownership]

  count  = length(aws_s3_bucket.cloudtrail_bucket)
  bucket = aws_s3_bucket.cloudtrail_bucket[count.index].id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "cloudtrail_bucket_versioning" {
  count  = length(aws_s3_bucket.cloudtrail_bucket)
  bucket = aws_s3_bucket.cloudtrail_bucket[count.index].id
  versioning_configuration {
    status = "Disabled"
  }
  mfa = "Disabled"
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_bucket_lifecycle" {
  provider = aws.subaccount
  count    = length(aws_s3_bucket.cloudtrail_bucket)
  bucket   = aws_s3_bucket.cloudtrail_bucket[count.index].id

  rule {
    id     = "cloudtrail-lifecycle-rule"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
