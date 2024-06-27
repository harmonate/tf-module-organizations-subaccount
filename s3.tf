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

resource "aws_s3_bucket" "config_bucket" {
  bucket        = local.config_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "config_bucket_ownership" {
  bucket = aws_s3_bucket.config_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "config_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.config_bucket_ownership]

  bucket = aws_s3_bucket.config_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "config_bucket_versioning" {
  bucket = aws_s3_bucket.config_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
  mfa = "Disabled"
}

resource "aws_s3_bucket_lifecycle_configuration" "config_bucket_lifecycle" {

  provider = aws.subaccount
  bucket   = aws_s3_bucket.config_bucket.id

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
  bucket        = local.cloudtrail_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "cloudtrail_bucket_ownership" {

  bucket = aws_s3_bucket.cloudtrail_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloudtrail_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.cloudtrail_bucket_ownership]


  bucket = aws_s3_bucket.cloudtrail_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "cloudtrail_bucket_versioning" {

  bucket = aws_s3_bucket.cloudtrail_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
  mfa = "Disabled"
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_bucket_lifecycle" {
  provider = aws.subaccount
  bucket   = aws_s3_bucket.cloudtrail_bucket.id

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
