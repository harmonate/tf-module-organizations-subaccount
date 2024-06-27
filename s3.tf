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

resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = aws_s3_bucket.config_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSConfigAclCheck20150319",
        Effect    = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action    = "s3:GetBucketAcl",
        Resource  = "${aws_s3_bucket.config_bucket.arn}"
      },
      {
        Sid       = "AWSConfigWrite20150319",
        Effect    = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.config_bucket.arn}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
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

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck20150319",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action    = "s3:GetBucketAcl",
        Resource  = "${aws_s3_bucket.cloudtrail_bucket.arn}"
      },
      {
        Sid       = "AWSCloudTrailWrite20150319",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.cloudtrail_bucket.arn}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "s3_permissions" {
  statement {
    actions = [
      "s3:PutBucketLifecycleConfiguration",
      "s3:GetBucketLifecycleConfiguration",
      "s3:DeleteBucketLifecycle",
      "s3:PutBucketPolicy",
      "s3:GetBucketPolicy",
      "s3:DeleteBucketPolicy",
      "s3:ListBucket",
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.config_bucket.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.config_bucket.bucket}/*",
      "arn:aws:s3:::${aws_s3_bucket.cloudtrail_bucket.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.cloudtrail_bucket.bucket}/*"
    ]
  }
}

resource "aws_iam_policy" "s3_permissions_policy" {
  name        = "S3PermissionsPolicy"
  description = "Policy for S3 bucket lifecycle configuration"
  policy      = data.aws_iam_policy_document.s3_permissions.json
}

resource "aws_iam_role_policy_attachment" "attach_s3_permissions" {
  role       = aws_iam_role.config_role.name
  policy_arn = aws_iam_policy.s3_permissions_policy.arn
}

